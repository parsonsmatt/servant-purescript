-- File auto generated by servant-purescript! --
module Counter.WebAPI.MakeRequests where

import Prelude

import Control.Monad.Aff.Class (class MonadAff, liftAff)
import Control.Monad.Error.Class (class MonadError)
import Control.Monad.Reader.Class (ask, class MonadReader)
import Counter.ServerTypes (AuthToken, CounterAction)
import Counter.WebAPI (SPParams_(..))
import Data.Argonaut.Generic.Aeson (decodeJson, encodeJson)
import Data.Argonaut.Printer (printJson)
import Data.Maybe (Maybe(..))
import Data.Nullable (Nullable(), toNullable)
import Data.Tuple (Tuple(..))
import Global (encodeURIComponent)
import Network.HTTP.Affjax (AJAX)
import Prim (Int, String)
import Servant.PureScript.Affjax (AjaxError(..), affjax, defaultRequest)
import Servant.PureScript.Settings (SPSettings_(..), gDefaultToURLPiece)
import Servant.PureScript.Util (encodeHeader, encodeListQuery, encodeQueryItem, encodeURLPiece, getResult)
import Servant.Subscriber (ToUserType)
import Servant.Subscriber.Request (HttpRequest(..))
import Servant.Subscriber.Subscriptions (Subscriptions, makeSubscriptions)
import Servant.Subscriber.Types (Path(..))
import Servant.Subscriber.Util (TypedToUser, subGenFlagQuery, subGenListQuery, subGenNormalQuery, toUserType)

getCounter :: forall m. MonadReader (SPSettings_ SPParams_) m => m HttpRequest
getCounter = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authToken = spParams_.authToken
  let baseURL = spParams_.baseURL
  let httpMethod = "GET"
  let reqPath = Path ["counter"]
  let reqHeaders =
        [Tuple "AuthToken" (gDefaultToURLPiece authToken)]
  let reqQuery =
        []
  let spReq = HttpRequest
                { httpMethod: httpMethod
                , httpPath: reqPath
                , httpHeaders: reqHeaders
                , httpQuery: reqQuery
                , httpBody: ""
                }
  pure spReq

putCounter :: forall m. MonadReader (SPSettings_ SPParams_) m => CounterAction
              -> m HttpRequest
putCounter reqBody = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authToken = spParams_.authToken
  let baseURL = spParams_.baseURL
  let httpMethod = "PUT"
  let reqPath = Path ["counter"]
  let reqHeaders =
        [Tuple "AuthToken" (gDefaultToURLPiece authToken)]
  let reqQuery =
        []
  let spReq = HttpRequest
                { httpMethod: httpMethod
                , httpPath: reqPath
                , httpHeaders: reqHeaders
                , httpQuery: reqQuery
                , httpBody: printJson <<< encodeJson $ reqBody
                }
  pure spReq

getCounterQueryparam :: forall m. MonadReader (SPSettings_ SPParams_) m => Int
                        -> m HttpRequest
getCounterQueryparam foo = do
  spOpts_' <- ask
  let spOpts_ = case spOpts_' of SPSettings_ o -> o
  let spParams_ = case spOpts_.params of SPParams_ ps_ -> ps_
  let authToken = spParams_.authToken
  let baseURL = spParams_.baseURL
  let httpMethod = "GET"
  let reqPath = Path ["counter" , "query-param"]
  let reqHeaders =
        [Tuple "AuthToken" (gDefaultToURLPiece authToken)]
  let reqQuery =
        subGenNormalQuery "foo" foo
  let spReq = HttpRequest
                { httpMethod: httpMethod
                , httpPath: reqPath
                , httpHeaders: reqHeaders
                , httpQuery: reqQuery
                , httpBody: ""
                }
  pure spReq

