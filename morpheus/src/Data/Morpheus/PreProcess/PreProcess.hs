{-# LANGUAGE FlexibleInstances   #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeOperators       #-}

module Data.Morpheus.PreProcess.PreProcess
  ( preProcessQuery
  ) where

import           Data.Map                                         (fromList)
import           Data.Morpheus.Error.Mutation                     (mutationIsNotDefined)
import           Data.Morpheus.PreProcess.Fragment                (validateFragments)
import           Data.Morpheus.PreProcess.Resolve.ResolveRawQuery (resolveRawQuery)
import           Data.Morpheus.PreProcess.Validate.Validate       (mapSelectorValidation)
import           Data.Morpheus.PreProcess.Variable                (allVariableReferences, resolveOperationVariables)
import           Data.Morpheus.Schema.Internal.Types              (GObject (..), ObjectField (..), OutputObject,
                                                                   TypeLib (..))
import qualified Data.Morpheus.Schema.Internal.Types              as SC (Field (..))
import           Data.Morpheus.Schema.TypeKind                    (TypeKind (..))
import           Data.Morpheus.Types.Error                        (Validation)
import           Data.Morpheus.Types.Query.Operator               (Operator (..), RawOperator, ValidOperator,
                                                                   VariableDefinitions)
import           Data.Morpheus.Types.Query.RawSelection           (RawSelectionSet)
import           Data.Morpheus.Types.Query.Selection              (SelectionSet)
import           Data.Morpheus.Types.Types                        (GQLQueryRoot (..))
import           Data.Text                                        (Text)

updateQuery :: RawOperator -> SelectionSet -> ValidOperator
updateQuery (Query name' _ _ pos) sel    = Query name' [] sel pos
updateQuery (Mutation name' _ _ pos) sel = Mutation name' [] sel pos

fieldSchema :: [(Text, ObjectField)]
fieldSchema =
  [ ( "__schema"
    , ObjectField
        { args = []
        , fieldContent =
            SC.Field
              { SC.fieldName = "__schema"
              , SC.notNull = True
              , SC.asList = False
              , SC.kind = OBJECT
              , SC.fieldType = "__Schema"
              }
        })
  ]

setFieldSchema :: GObject ObjectField -> GObject ObjectField
setFieldSchema (GObject fields core) = GObject (fields ++ fieldSchema) core

getOperator :: RawOperator -> TypeLib -> Validation (OutputObject, VariableDefinitions, RawSelectionSet)
getOperator (Query _ args' sel _) lib' = pure (snd $ query lib', args', sel)
getOperator (Mutation _ args' sel position') lib' =
  case mutation lib' of
    Just (_, mutation') -> pure (mutation', args', sel)
    Nothing             -> Left $ mutationIsNotDefined position'

resolveValues :: TypeLib -> GQLQueryRoot -> Validation (OutputObject, SelectionSet)
resolveValues typesLib root = do
  (query', args', rawSel) <- getOperator (queryBody root) typesLib
  variables' <-
    resolveOperationVariables typesLib (fromList $ inputVariables root) (allVariableReferences [rawSel]) args'
  validateFragments typesLib root
  let operator' = setFieldSchema query'
  selection' <- resolveRawQuery typesLib (fragments root) variables' rawSel operator'
  pure (operator', selection')

preProcessQuery :: TypeLib -> GQLQueryRoot -> Validation ValidOperator
preProcessQuery lib' root' = do
  (operatorType', selection') <- resolveValues lib' root'
  selectors <- mapSelectorValidation lib' operatorType' selection'
  pure $ updateQuery (queryBody root') selectors
