{-# LANGUAGE CPP, ForeignFunctionInterface, EmptyDataDecls #-}

module Text.XkbCommon.Context
	( Context(..), ContextFlags, defaultFlags, newContext,
	  appendIncludePath, numIncludePaths,
	) where

import Foreign
import Foreign.C
import Foreign.Storable
import Data.IORef
import Data.Functor
import Control.Monad (liftM, ap)
import Control.Monad.Trans.Maybe (MaybeT)

import Text.XkbCommon.InternalTypes

#include <xkbcommon/xkbcommon.h>



-- construct a new Xkb context
newContext :: ContextFlags -> IO (Maybe Context)
newContext c = do
	k <- c_new_context $ translateContextFlags c
	if k == nullPtr
		then return Nothing
		else do
			l <- newForeignPtr c_unref_context k
			return $ Just $ toContext l

-- stateful handling of Xkb context search paths for keymaps
appendIncludePath :: Context -> String -> IO (Maybe ())
appendIncludePath c str = withCString str $
	\ cstr -> withContext c $
		\ ptr -> do
			err <- c_append_include_path_context ptr cstr
			return $ if err == 1
				then Just ()
				else Nothing


numIncludePaths :: Context -> IO Int
numIncludePaths c = withContext c $ (liftM fromIntegral) . c_num_include_paths_context


-- BORING TRANSLATION STUFF

type CContextFlags = #type int
#{enum CContextFlags,
	, noFlags       = 0
	, noEnvNamFlags = XKB_CONTEXT_NO_ENVIRONMENT_NAMES
	, noDefIncFlags = XKB_CONTEXT_NO_DEFAULT_INCLUDES
	, bothFlags     = XKB_CONTEXT_NO_DEFAULT_INCLUDES + XKB_CONTEXT_NO_ENVIRONMENT_NAMES
	}

translateContextFlags :: ContextFlags -> CContextFlags
translateContextFlags x = j + k where
	j = if noDefaultIncludes x then noEnvNamFlags else 0
	k = if noEnvironmentNames x then noDefIncFlags else 0





-- FOREIGN CCALLS


-- context related

foreign import ccall unsafe "xkbcommon/xkbcommon.h xkb_context_new"
	c_new_context :: CContextFlags -> IO (Ptr CContext)

foreign import ccall unsafe "xkbcommon/xkbcommon.h &xkb_context_unref"
	c_unref_context :: FinalizerPtr CContext

foreign import ccall unsafe "xkbcommon/xkbcommon.h xkb_context_include_path_append"
	c_append_include_path_context :: Ptr CContext -> CString -> IO CInt

foreign import ccall unsafe "xkbcommon/xkbcommon.h xkb_context_num_include_paths"
	c_num_include_paths_context :: Ptr CContext -> IO CUInt

{-
int 	xkb_context::xkb_context_include_path_append_default (struct xkb_context *context)
 	Append the default include paths to the contexts include path.

int 	xkb_context::xkb_context_include_path_reset_defaults (struct xkb_context *context)
 	Reset the context's include path to the default.

void 	xkb_context::xkb_context_include_path_clear (struct xkb_context *context)
 	Remove all entries from the context's include path.

unsigned int 	xkb_context::xkb_context_num_include_paths (struct xkb_context *context)
 	Get the number of paths in the context's include path.

const char * 	xkb_context::xkb_context_include_path_get (struct xkb_context *context, unsigned int index)
 	Get a specific include path from the context's include path.
-}


-- logging related
{-
void 	xkb_context::xkb_context_set_log_level (struct xkb_context *context, enum xkb_log_level level)
 	Set the current logging level.

enum xkb_log_level 	xkb_context::xkb_context_get_log_level (struct xkb_context *context)
 	Get the current logging level.

void 	xkb_context::xkb_context_set_log_verbosity (struct xkb_context *context, int verbosity)
 	Sets the current logging verbosity.

int 	xkb_context::xkb_context_get_log_verbosity (struct xkb_context *context)
 	Get the current logging verbosity of the context.

void 	xkb_context::xkb_context_set_log_fn (struct xkb_context *context, void(*log_fn)(struct xkb_context *context, enum xkb_log_level level, const char *format, va_list args))
 	Set a custom function to handle logging messages.
-}
