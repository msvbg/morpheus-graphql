{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ScopedTypeVariables , MultiParamTypeClasses , FlexibleContexts , RankNTypes , ExistentialQuantification  #-}

module Data.GraphqlHS.Generics.TypeRep
    ( Selectors(..)
    , ArgsMeta(..)
    )
where

import           Data.ByteString                ( ByteString )
import           Data.Proxy                     ( Proxy(..) )
import           GHC.Generics
import           Data.Text                      ( Text
                                                , pack
                                                )
import           Data.GraphqlHS.Types.Introspection
                                                ( GQL__Type(..)
                                                , GQL__Field(..)
                                                , GQL__TypeKind(..)
                                                , GQLTypeLib
                                                )
import           Data.Data                      ( Typeable
                                                , Data
                                                , typeOf
                                                )

class  Selectors rep where
    getFields ::  Proxy rep ->  [(GQL__Field,GQLTypeLib -> GQLTypeLib)]

instance Selectors f => Selectors (M1 D x f)  where
    getFields _ = getFields (Proxy :: Proxy f)

instance Selectors f => Selectors (M1 C x f)  where
    getFields _ = getFields (Proxy :: Proxy f)

instance (Selectors a, Selectors b ) => Selectors (a :*: b)  where
    getFields _ = getFields (Proxy :: Proxy a) ++ getFields(Proxy:: Proxy b)

instance Selectors U1 where
    getFields _ = []

class  ArgsMeta rep where
    getMeta ::  Proxy rep ->  [(Text, Text)]

instance ArgsMeta f => ArgsMeta (M1 D x f)  where
    getMeta _ = getMeta (Proxy :: Proxy f)

instance ArgsMeta f => ArgsMeta (M1 C x f)  where
    getMeta _ = getMeta (Proxy :: Proxy f)

instance (ArgsMeta a, ArgsMeta b ) => ArgsMeta (a :*: b)  where
    getMeta _ = getMeta (Proxy :: Proxy a) ++ getMeta (Proxy:: Proxy b)

instance ArgsMeta U1 where
    getMeta _ = []

instance (Selector s, Typeable t ) => ArgsMeta (M1 S s (K1 R t)) where
    getMeta _ = [( pack $ selName (undefined :: M1 S s (K1 R t) ()) , pack $ show $ typeOf (undefined::t) )]
