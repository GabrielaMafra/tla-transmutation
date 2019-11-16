module Helpers where

import Data.List
import Data.List.Extra
import qualified Text.Casing as Casing -- cabal install casing

import Head
import DocHandler
import Snippets

-- (MOD) helpers
moduleHeader (Module i doc) = "defmodule " ++ pascal i ++ " do\n" ++ ident (moduleDoc doc ++ oracleDelaration)

moduleContext (Module m _) = [(m,"module")]

mainCall (Module i _) s = pascal i ++ ".main(\n" ++ ident s ++ "\n)\n"

-- (CALL) helpers
call i [] = snake i
call i ps = snake i ++ "(" ++ intercalate ", " (ps) ++ ")"

-- (IF) helpers
ifExpr c t e = unlines ["if " ++ c ++ " do",
                        ident t,
                        "else",
                        ident e,
                        "end"]

-- (REC-LIT) helpers
isLiteral ((Key _), _) = True
isLiteral _ = False

-- (INFO-*) helpers
actionName (ActionCall i ps) = i ++ "(" ++ intercalate ", " (map interpolate ps) ++ ")"
actionName a = show a

-- Others
cFold :: [ElixirCode] -> ElixirCode
cFold [] = "True"
cFold cs = intercalate " and " cs

aFold :: [ElixirCode] -> ElixirCode
aFold [] = "variables"
aFold as = let (otherActions, actions) = partition preassignment as
               kvs = intercalate ",\n" (map keyValue actions)
               initialVariables = case actions of
                                    [] -> []
                                    _ -> ["%{\n" ++ ident kvs ++ "\n}"]
           in mapMerge (initialVariables ++ otherActions)

keyValue a = drop 3 (dropEnd 2 a)

mapMerge [m] = m
mapMerge (m:ms) = "Map.merge(\n  " ++ m ++ ",\n" ++ ident (mapMerge ms) ++ ")\n"

preassignment as = (head as) == '(' || take 2 as == "if" || dropWhile (/= ':') as == []

interpolate i = "#{inspect " ++ i ++ "}"

declaration i ps =  "def " ++ snake i ++ "(" ++ intercalate ", " ("variables": ps) ++ ") do\n"

identAndSeparate sep ls = (intercalate (sep ++ "\n") (map ((++) "  ") ls))

unzipAndFold :: [([a],[b])] -> ([a],[b])
unzipAndFold = foldr (\x (a, b) -> (fst x ++ a, snd x ++ b)) ([],[])

snake i = Casing.toQuietSnake (Casing.fromAny i)
pascal i = Casing.toPascal (Casing.fromAny i)

ident block = intercalate "\n" (map tabIfline (lines block))

mapAndJoin f ls = intercalate "\n" (map f ls)

tabIfline [] = []
tabIfline xs = "  " ++ xs

isNamed i (Definition id _ _ _) = i == id
isNamed _ _ = False

specialDef :: String -> String -> Definition -> Bool
specialDef _ _ (Constants _) = True
specialDef i n d = (isNamed i d) || (isNamed n d)

findConstants ds = concat (map (\d -> case d of {Constants cs -> cs; _ -> [] }) ds)

findIdentifier i ds = case find (isNamed i) ds of
                        Just a -> a
                        Nothing -> error("Definition not found: " ++ (show i))
