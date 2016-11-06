-- File auto generated by servant-purescript! --
module Counter.WebAPI where

import Prelude

import Control.Monad.Aff.Class (class MonadAff, liftAff)
import Control.Monad.Error.Class (class MonadError)
import Control.Monad.Reader.Class (ask, class MonadReader)
import Counter.ServerTypes (AuthToken, CounterAction)
import Data.Argonaut.Generic.Aeson (decodeJson, encodeJson)
import Data.Argonaut.Printer (printJson)
import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable(), toNullable)
import Global (encodeURIComponent)
import Network.HTTP.Affjax (AJAX)
import Prim (Int, String)
import Servant.PureScript.Affjax (AjaxError(..), affjax, defaultRequest)
import Servant.PureScript.Settings (SPSettings_(..), gDefaultToURLPiece)
import Servant.PureScript.Util (encodeHeader, encodeListQuery, encodeQueryItem, encodeURLPiece, getResult)

newtype SPParams_ = SPParams_ { authToken :: AuthToken
                              , baseURL :: String
                              }

getCounter :: forall eff m.
              (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
              => m Int
getCounter = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authToken = spParams_.authToken
  let baseURL = spParams_.baseURL
  let httpMethod = "GET"
  let reqUrl = baseURL <> "counter"
  let reqHeaders =
        [{ field : "AuthToken" , value : encodeHeader spOpts_' authToken
         }]
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
putCounter :: forall eff m.
              (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
              => CounterAction -> m Int
putCounter reqBody = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authToken = spParams_.authToken
  let baseURL = spParams_.baseURL
  let httpMethod = "PUT"
  let reqUrl = baseURL <> "counter"
  let reqHeaders =
        [{ field : "AuthToken" , value : encodeHeader spOpts_' authToken
         }]
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 , content = toNullable <<< Just <<< printJson <<< encodeJson $ reqBody
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
getCounterQueryparam :: forall eff m.
                        (MonadReader (SPSettings_ SPParams_) m, MonadError AjaxError m, MonadAff ( ajax :: AJAX | eff) m)
                        => Int -> m String
getCounterQueryparam foo = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authToken = spParams_.authToken
  let baseURL = spParams_.baseURL
  let httpMethod = "GET"
  let reqUrl = baseURL <> "counter" <> "/" <> "query-param" 
        <> "?" <> encodeQueryItem spOpts_' "foo" foo
  let reqHeaders =
        [{ field : "AuthToken" , value : encodeHeader spOpts_' authToken
         }]
  let affReq = defaultRequest
                 { method = httpMethod
                 , url = reqUrl
                 , headers = defaultRequest.headers <> reqHeaders
                 }
  affResp <- affjax affReq
  getResult affReq decodeJson affResp
  
