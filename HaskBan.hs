{-# LANGUAGE NoMonomorphismRestriction, FlexibleContexts #-}
module HaskBan (main) where

  -- ncurses (gui) library
  import UI.HSCurses.Curses
  
  -- haskban internals
  import HaskBan.Curses
  import HaskBan.Logic
  import HaskBan.Monad
  import HaskBan.Types 
  import HaskBan.Parser (parseSokoMaps)
  import HaskBan.Printer 

  -- others
  import Data.List (sort)
  import Control.Monad (mapM_, liftM, forever)
  import Control.Monad.State
  import qualified Data.ByteString as BS
  import qualified Data.IntMap as IM ((!))
  import Data.Map ((!), Map)
  
  main :: SokobanMonad ()
  main = do
    window <- liftIO setupHaskBanGUI
    liftIO refresh
    liftIO $ showMoves 0
    loopUntil (readKeyAndPrint window)
    liftIO $ endWin

  loopUntil :: (Monad m) => m Bool -> m ()
  loopUntil action = do
    shouldFinish <- action
    when (not shouldFinish) (loopUntil action)

  readKeyAndPrint :: Window -> SokobanMonad Bool
  readKeyAndPrint window = do
    displaySokobanMap window
    key <- liftIO getCh
    if shouldTerminate key
      then do
        liftIO endWin
        return True
      else do
        isFinished <- keyPressed key
        --bs <- sort `liftM` getBoxesPositions
        --ts <- sort `liftM` getTargetPositions
        --liftIO $ mvWAddStr window 19 0 (show $ length bs)
        --liftIO $ mvWAddStr window 20 0 (show bs)
        --liftIO $ mvWAddStr window 21 0 (show $ length ts)
        --liftIO $ mvWAddStr window 22 0 (show ts)
        when isFinished (liftIO (wclear window >> printYouWonScreen window))
        liftIO $ refresh
        return isFinished

  showMoves :: Int -> IO ()
  showMoves s = mvWAddStr stdScr 3 30 ("Number of moves: " ++ show s)

  -- keyPressed :: (MonadState SokobanInfo) m => Key -> m ()
  keyPressed :: Key -> SokobanMonad Bool
  keyPressed k = do 
    let t = getTranslation k
    movePlayer t
  
  getTranslation :: Key -> Translation
  getTranslation key | key == KeyUp    || key == (KeyChar 'k') = translateUp
                     | key == KeyDown  || key == (KeyChar 'j') = translateDown
                     | key == KeyLeft  || key == (KeyChar 'h') = translateLeft
                     | key == KeyRight || key == (KeyChar 'l') = translateRight
                     | otherwise                               = (\(x, y) -> (x, y))

  shouldTerminate :: Key -> Bool
  shouldTerminate (KeyChar '\ESC') = True
  shouldTerminate (KeyChar 'q')    = True 
  shouldTerminate _                = False 

  displaySokobanMap :: Window -> SokobanMonad ()
  displaySokobanMap window = do
    sokobanMap <- getMap
    liftIO $ do
      let sokoMapStr = showSokoMap sokobanMap
      mvWAddStr window 2 0 sokoMapStr 
      refresh
