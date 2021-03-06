-- | Test whether a certain number of observations are sufficient
-- to generate samples of identical weight by SMC

module TestSMCObservations where

import Data.List
import System.Random

import Control.Monad.Bayes.LogDomain (LogDomain)
import Control.Monad.Bayes.Class
import Control.Monad.Bayes.Empirical
import Control.Monad.Bayes.Inference
import Control.Monad.Bayes.Particle
import Control.Monad.Bayes.Sampler

import qualified HMM as HMM

g = mkStdGen 0

smcParticles :: Int -> Int -> Particle (Population Sampler) a -> [(a, LogDomain Double)]
smcParticles observations particles model = sample (runPopulation $ smc observations particles model) g

sameWeights :: [(a, LogDomain Double)] -> Bool
sameWeights xs = length (nub $ map snd xs) == 1

-- | Check whether the weights of SMC particles are equal.
check_smc_weight :: Int -> Int -> Particle (Population Sampler) a -> Bool
check_smc_weight observations particles model =
  let
    samples = smcParticles observations particles model
  in
    length samples == particles && sameWeights samples
