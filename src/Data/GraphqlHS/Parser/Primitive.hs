{-# LANGUAGE OverloadedStrings #-}

module Data.GraphqlHS.Parser.Primitive where

import           Data.Text  (Text, pack)
import           Data.Attoparsec.Text 
import           Control.Applicative
import           Data.GraphqlHS.Types.Types     ( GQLValue(..) ,  GQLPrimitive(..) )

replaceType :: Text -> Text
replaceType "type" = "_type"
replaceType x      = x

boolTrue :: Parser GQLPrimitive
boolTrue = string "true" *> pure (JSBool True)

boolFalse :: Parser GQLPrimitive
boolFalse = string "false" *> pure (JSBool False)

jsBool :: Parser GQLPrimitive
jsBool = boolTrue <|> boolFalse

jsString :: Parser GQLPrimitive
jsString = do 
    char '"' 
    value <- (many (notChar '"'))
    char '"'
    pure (JSString $ pack value)

token :: Parser Text
token = (replaceType . pack) <$> some (letter <|> char '_')

variable :: Parser Text
variable = skipSpace *> char '$' *> token

field :: Text -> Parser GQLValue
field key = pure $ Field $ key

seperator :: Parser Char
seperator = char ',' <|> char ' ' <|> char '\n' <|> char '\t'