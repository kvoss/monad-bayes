{-# LANGUAGE
 FlexibleContexts,
 TypeFamilies
 #-}

module HMM (
            hmm,
--            exactMarginals
           ) where

--Hidden Markov Models

--import Numeric.LinearAlgebra.HMatrix -- for the exact posterior only

import Control.Monad.Bayes.Class
import Control.Monad.Bayes.Primitive
import qualified Control.Monad.Bayes.Dist as Dist

-- | States of the HMM
states :: [Int]
states = [-1,0,1]

-- | Observed values
values :: [Double]
values = [0.9,0.8,0.7,0,-0.025,5,2,0.1,0,
          0.13,0.45,6,0.2,0.3,-1,-1]

-- | The transition model.
trans :: MonadDist m => Int -> m Int
trans (-1) = categorical $ zip states [0.1, 0.4, 0.5]
trans 0    = categorical $ zip states [0.2, 0.6, 0.2]
trans 1    = categorical $ zip states [0.15,0.7,0.15]

-- | The emission model.
emission :: Int -> Primitive Double Double
emission x = Continuous (Normal (fromIntegral x) 1)

-- | Initial state distribution
start :: MonadDist m => m [Int]
start = uniformD $ map (:[]) states

-- | Example HMM from http://dl.acm.org/citation.cfm?id=2804317
hmm :: (MonadBayes m, CustomReal m ~ Double) => m [Int]
hmm = fmap reverse states where
  states = foldl expand start values
  --expand :: MonadBayes m => m [Int] -> Double -> m [Int]
  expand d y = do
    rest <- d
    x    <- trans $ head rest
    observe (emission x) y
    return (x:rest)


------------------------------------------------------------
-- Exact marginal posterior with forward-backward

-- exactMarginals :: MonadDist d => [d Int]
-- exactMarginals = map marginal [1 .. length values] where
--     marginal i = categorical $ zip states $ map (logFloat . lookup i) [1 .. length states]
--     lookup = hmmExactMarginal initial tmatrix scores
--
-- initial :: Vector Double
-- initial = fromList $ map snd $ Dist.explicit $ start
--
-- tmatrix :: Matrix Double
-- tmatrix = fromColumns $ map (fromList . map snd . Dist.explicit . trans) states
--
-- scores :: [Vector Double]
-- scores = map (\y -> fromList $ map (fromLogFloat . (\x -> pdf (emission x) y)) states) values
--
-- -- | Runs forward-backward, then looks up the probability of ith latent
-- -- variable being in state s.
-- hmmExactMarginal :: Vector Double -> Matrix Double -> [Vector Double]
--                     -> Int -> Int -> Double
-- hmmExactMarginal init trans obs =
--   let
--     marginals = forwardBackward init trans obs
--     n = length obs
--     lookup i s = marginals ! s ! i
--   in
--    lookup
--
-- -- | Runs forward-backward, then looks up the probability  of a sequence of states.
-- hmmExact :: Vector Double -> Matrix Double -> [Vector Double] -> [Int] -> Double
-- hmmExact init trans obs =
--     let
--         marginals = forwardBackward init trans obs
--         n = length obs
--         lookup i [] = if i == n then 1 else error "Dimension mismatch"
--         lookup i (x:xs) = (marginals ! x ! i) * lookup (i+1) xs
--     in
--         lookup 0
--
-- -- | Produces marginal posteriors for all state variables using forward-backward.
-- -- In the resulting matrix the row index is state and column index is time.
-- forwardBackward :: Vector Double -> Matrix Double -> [Vector Double] -> Matrix Double
-- forwardBackward init trans obs = alphas * betas where
--     (alphas,cs) = forward  init trans obs
--     betas       = backward init trans obs cs
--
-- forward :: Vector Double -> Matrix Double -> [Vector Double] -> (Matrix Double, Vector Double)
-- forward init trans obs = (fromColumns as, fromList cs) where
--     run p [] = ([],[])
--     run p (w:ws) = (a:as, c:cs) where
--         a' = w * (trans #> p)
--         a  = scale c a'
--         c  = 1 / norm_1 a'
--         (as,cs) = run a ws
--     (as,cs) = run init obs
--
-- backward :: Vector Double -> Matrix Double -> [Vector Double] -> Vector Double -> Matrix Double
-- backward init trans obs cs = fromColumns bs where
--     run :: Vector Double -> [Vector Double] -> [Double] -> [Vector Double]
--     run p [] [] = []
--     run p (w:ws) (c:cs) = p:bs where
--         b  = scale c (t #> (w * p))
--         bs = run b ws cs
--     t = tr trans
--     bs = reverse $ run (cmap (const 1) init) (reverse obs) (reverse (toList cs))
--     n = length obs
