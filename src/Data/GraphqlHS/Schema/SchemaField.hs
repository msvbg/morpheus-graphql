{-# LANGUAGE TypeOperators , FlexibleInstances , ScopedTypeVariables #-}

module Data.GraphqlHS.Schema.SchemaField
    ( selectFieldBykey
    , getFieldTypeByKey
    , fieldArgsByKey
    )
where

import           Prelude                 hiding ( lookup )
import           Data.List                      ( find )
import           Data.Map                       ( elems
                                                , mapWithKey
                                                , lookup
                                                , toList
                                                )
import           Data.Data                      ( Data )
import           Data.Text                      ( Text(..)
                                                , pack
                                                , unpack
                                                )
import           Data.GraphqlHS.Types.Types     ( Eval(..)
                                                , (::->)(..)
                                                , GQLType
                                                , GQLValue(..)
                                                )
import           Data.GraphqlHS.ErrorMessage    ( semanticError
                                                , handleError
                                                )
import           Data.GraphqlHS.Types.Introspection
                                                ( GQL__Field(..)
                                                , GQL__Type(fields)
                                                , GQL__InputValue
                                                )
import          Control.Monad                   (join)


selectFieldBykey :: Text -> GQL__Type -> Maybe GQL__Field
selectFieldBykey key gqlType = case (fields gqlType) of
    Some fields -> find (\x -> key == (name x)) fields
    _           -> Nothing

getFieldTypeByKey :: Text -> GQL__Type -> Maybe GQL__Type
getFieldTypeByKey key gqlType = join( _type <$> selectFieldBykey key gqlType )

fieldArgsByKey :: Text -> GQL__Type -> Maybe [GQL__InputValue]
fieldArgsByKey key gqlType = args <$> selectFieldBykey key gqlType
