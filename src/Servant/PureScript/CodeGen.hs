{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TypeOperators         #-}

module Servant.PureScript.CodeGen where

import           Servant.PureScript.Internal
import           Text.PrettyPrint.Mainland

import           Control.Lens                        hiding (List)
import           Data.Aeson
import           Data.Map                            (Map)
import qualified Data.Map                            as Map
import           Data.Maybe                          (mapMaybe, maybeToList)
import           Data.Monoid
import           Data.Proxy
import           Data.Set                            (Set)
import qualified Data.Set                            as Set
import           Data.Text                           (Text)
import qualified Data.Text                           as T
import qualified Data.Text.Encoding                  as T
import           Data.Typeable
import           GHC.Generics                        hiding (to)
import           Language.PureScript.Bridge
import           Language.PureScript.Bridge.Printer
import           Language.PureScript.Bridge.TypeInfo
import           Network.HTTP.Types.URI              (urlEncode)
import           Servant.API
import           Servant.Foreign

genModule :: Settings -> [Req TypeInfo] -> Doc
genModule opts reqs = let
    apiImports = reqsToImportLines reqs
    imports = mergeImportLines (standardImports opts) apiImports
    importLines = map (strictText . importLineToText) . Map.elems $ imports
  in
        "-- File auto generated by servant-purescript! --"
    </> "module" <+> strictText (apiModuleName opts) <+> "where" <> line
    </> docIntercalate line importLines <> line
    </> genParamSettings opts <> line
    </> (docIntercalate line . map (genFunction opts)) reqs

genParamSettings :: Settings -> Doc
genParamSettings opts = let
  genEntry arg = arg ^. pName ^. to strictText <+> "::" <+> arg ^. pType ^. to typeName ^. to strictText
  in
    "type Params =" <+/> align (
              lbrace
          <+> (docIntercalate (line <> ", ") . map genEntry . Set.toList . readerParams) opts
          </> rbrace
          )

genFunction :: Settings -> Req TypeInfo -> Doc
genFunction opts req = let
    fnName = req ^. reqFuncName ^. camelCaseL
    allParamsList = baseURLParam : reqToParams req
    allParams = Set.fromList allParamsList
    allRParams = readerParams opts
    fnParams = filter (not . flip Set.member allRParams) allParamsList -- Use list not set, as we don't want to change order of parameters
    rParams = Set.toList $ allRParams `Set.intersection` allParams

    pTypes = map _pType fnParams
    pNames = map _pName fnParams
    signature = genSignature fnName pTypes (req ^. reqReturnType)
    body = genFnHead fnName pNames <+> genFnBody rParams req
  in signature </> body


genGetReaderParams :: [Param TypeInfo] -> Doc
genGetReaderParams = stack . map (genGetReaderParam . strictText . _pName)
  where
    genGetReaderParam pName = "let" <+> pName <+> "= spOpts_.params." <> pName


genSignature :: Text -> [TypeInfo] -> Maybe TypeInfo -> Doc
genSignature fnName params mRet = fName <+> align (constraint <+/> parameterString)
  where
    fName = strictText fnName
    constraint = ":: forall eff m." <+/> "(MonadReader (Settings Params) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)" <+/> "=>"
    retName = maybe "Unit" (strictText . typeInfoToText True) mRet
    retString = "m" <+> retName
    typeNames = map (strictText . typeInfoToText True) params
    parameterString = docIntercalate (softline <> "-> ") (typeNames <> [retString])

genFnHead :: Text -> [Text] -> Doc
genFnHead fnName params = fName <+> align (docIntercalate softline docParams <+> "=")
  where
    docParams = map strictText params
    fName = strictText fnName

genFnBody :: [Param TypeInfo] -> Req TypeInfo -> Doc
genFnBody rParams req = "do"
    </> indent 2 (
         "spOpts_ <- ask"
      </> genGetReaderParams rParams
      </> hang 6 ("let httpMethod =" <+> dquotes (req ^. reqMethod ^. to T.decodeUtf8 ^. to strictText))
      </> hang 6 ("let reqUrl ="     <+> genBuildURL (req ^. reqUrl))
      </> "let reqHeaders =" </> indent 6 (req ^. reqHeaders ^. to genBuildHeaders)
      </> "affResp <- affjax defaultRequest" </> indent 6 (
            "{ method :"  <+> "httpMethod"
        </> ", url :"     <+> "reqUrl"
        </> ", headers :" <+> "reqHeaders"
        </> case req ^. reqBody of
              Nothing -> "}"
              Just _  -> ", content :" <+> "spOpts_.encodeJson reqBody" </> "}"
      )
      </> "getResult affResp" <> line
    )

genBuildURL :: Url TypeInfo -> Doc
genBuildURL url = "spOpts_." <> strictText baseURLId <+> "<>"
    <+> genBuildPath (url ^. path ) <+> genBuildQuery (url ^. queryStr)

----------
genBuildPath :: Path TypeInfo -> Doc
genBuildPath = docIntercalate (softline <> "<> \"/\" <> ") . map (genBuildSegment . unSegment)

genBuildSegment :: SegmentType TypeInfo -> Doc
genBuildSegment (Static (PathSegment seg)) = dquotes $ strictText (textURLEncode False seg)
genBuildSegment (Cap arg) = parens $ "encodeURIComponent" <+> strictText (arg ^. argName ^. to unPathSegment)

----------
genBuildQuery :: [QueryArg TypeInfo] -> Doc
genBuildQuery [] = ""
genBuildQuery args = softline <> "<> \"?\" <> " <> (docIntercalate (softline <> "<> \"&\" <> ") . map genBuildQueryArg $ args)

genBuildQueryArg :: QueryArg TypeInfo -> Doc
genBuildQueryArg arg = case arg ^. queryArgType of
    Normal -> genQueryEncoding "encodeQuery"
    Flag   -> genQueryEncoding "encodeQuery"
    List   -> genQueryEncoding "encodeListQuery"
  where
    argText = arg ^. queryArgName ^. argName ^. to unPathSegment
    encodedArgName = strictText . textURLEncode True $ argText
    genQueryEncoding fn = fn <+> dquotes encodedArgName <+> strictText argText

-----------

genBuildHeaders :: [HeaderArg TypeInfo] -> Doc
genBuildHeaders = list . map genBuildHeader

genBuildHeader :: HeaderArg TypeInfo -> Doc
genBuildHeader (HeaderArg arg) = let
    argText = arg ^. argName ^. to unPathSegment
    encodedArgName = strictText . textURLEncode True $ argText
  in
    align $ "{ field : " <> dquotes encodedArgName
      <+/> comma <+> "value :"
      <+> "(encodeURIComponent <<< spOpts_.toURLPiece)" <+> strictText argText
      </> "}"
genBuildHeader (ReplaceHeaderArg _ _) = error "ReplaceHeaderArg - not yet implemented!"

reqsToImportLines :: [Req TypeInfo] -> ImportLines
reqsToImportLines = typesToImportLines Map.empty . concatMap reqToTypeInfos

reqToTypeInfos :: Req TypeInfo -> [TypeInfo]
reqToTypeInfos req = map _pType (reqToParams req) ++ maybeToList (req ^. reqReturnType)

-- | Extract all function parameters from a given Req.
reqToParams :: Req f -> [Param f]
reqToParams req = fmap headerArgToParam (req ^. reqHeaders)
               ++ maybeToList (reqBodyToParam (req ^. reqBody))
               ++ urlToParams (req ^. reqUrl)

urlToParams :: Url f -> [Param f]
urlToParams url = mapMaybe (segmentToParam . unSegment) (url ^. path) ++ map queryArgToParam (url ^. queryStr)

segmentToParam :: SegmentType f -> Maybe (Param f)
segmentToParam (Static _) = Nothing
segmentToParam (Cap arg) = Just Param {
    _pType = arg ^. argType
  , _pName = arg ^. argName ^. to unPathSegment
  }

queryArgToParam :: QueryArg f -> Param f
queryArgToParam arg = Param {
    _pType = arg ^. queryArgName ^. argType
  , _pName = arg ^. queryArgName ^. argName ^. to unPathSegment
  }

headerArgToParam :: HeaderArg f -> Param f
headerArgToParam (HeaderArg arg) = Param {
    _pName = arg ^. argName ^. to unPathSegment
  , _pType = arg ^. argType
  }
headerArgToParam _ = error "We do not support ReplaceHeaderArg - as I have no idea what this is all about."

reqBodyToParam :: Maybe f -> Maybe (Param f)
reqBodyToParam = fmap (Param "reqBody")

docIntercalate :: Doc -> [Doc] -> Doc
docIntercalate i = mconcat . punctuate i


textURLEncode :: Bool -> Text -> Text
textURLEncode spaceIsPlus = T.decodeUtf8 . urlEncode spaceIsPlus . T.encodeUtf8
