{-# OPTIONS_GHC -Wno-unrecognised-pragmas #-}

{-# HLINT ignore "Use <$>" #-}
-- ghc -I. --make Parsing.hs
import Parsing

data Onion = Core Integer | Layer Onion deriving (Show)

onion :: Parser Onion
onion =
  do
    y <- char 'L'
    rest <- onion
    return (Layer rest)
    <|> do
      c <- core
      return (Core c)

core :: Parser Integer
core = toInteger <$> int

theonion :: String -> Either String Onion
theonion inp = case (parse onion inp) of
  [(o, "")] -> Right o
  [(_, out)] -> Left out
  [] -> Left "invalid input"

type AB = String

ab :: Parser AB -- does not work with empty input, which is recognized by L
ab =
  do
    a <- char 'a'
    b <- char 'b'
    return (a : [b])
    <|> do
      a <- char 'a'
      mid <- ab
      b <- char 'b'
      return ([a] ++ mid ++ [b])

-- 1. exericise
-- expr ::= <term> + <expr> | <term>
-- it is not a good idea to use the alternative implementation of expr
-- all rules for expr start with term, so parsing a term alone will always succed and result in "+ <expr>" being left unconsumed.
-- The rest of the input string cannot be parsed by any part of expr
-- Read: common prefix problem
data B = B Bexp | T Term | A Atom deriving Show

data Bexp = And Term Bexp | Or Term Bexp | Term Term deriving Show

data Term = Not Atom | An Atom deriving Show

data Atom = TT | FF | Be Bexp deriving Show

b :: Parser Bexp
b =
  do
    x <- t
    string "and"
    y <- b
    return (And x y)
    <|> do
      x <- t
      string "or"
      y <- b
      return (Or x y)
    <|> do
      x <- t
      return (Term x)

t :: Parser Term
t =
  do
    string "not"
    x <- a
    return (Not x)
    <|> do
        x <- a
        return (An x)

a :: Parser Atom
a =
  do
    string "t"
    return TT
    <|> do
      string "f"
      return FF
    <|> do
      string "("
      x <- b
      string ")"
      return (Be x)

boolean = do
    bexp <- b
    return $ B bexp
    <|> do
        term <- t
        return $ T term
        <|> do
            atom <- a
            return $ A atom

validBexp xs = parse boolean xs

invalidBexp = null (validBexp "notort")

aValidBexp = validBexp "(torf)andf"



evaluator :: B -> Bool
evaluator (B bexp) = evalb bexp
evaluator (T term) = evalt term
evaluator (A atom) = evala atom

evalb :: Bexp -> Bool
evalb (And t b) = (evalt t) && (evalb b)
evalb (Or t b) = (evalt t) || (evalb b)
evalb (Term t) = evalt t

evalt :: Term -> Bool
evalt (Not a) = not (evala a)
evalt (An a) = evala a

evala :: Atom -> Bool
evala (TT) = True
evala (FF) = False
evala (Be b) = evalb b

-- trueorfalseandfalse = evaluator $ fst $ head aValidBexp

evalBexp :: String -> Maybe Bool
evalBexp inp = case (parse boolean inp) of 
    [(t,"")] -> Just $ evaluator t
    _ -> Nothing

-- this should be able to evaluate multiple trees (in case of ambiguous parses)
evalBexp' inp = do
  (bexp,rest) <- parse boolean inp
  if not $ null rest then return Nothing else return $ Just (evaluator bexp)

trueorfalseandfalse = evalBexp "(torf)andf" -- should evaluate to `Just False`
trueorfalseandtrue = evalBexp "(torf)andt" -- should evaluate to `Just True`

notaBexp = evalBexp "t+1" -- shouldnt evaluate to a boolean valuea