
-- BLT Update Callbacks
-- If you want to only conditionally enable updates for your mod, define
--   a function onto this table and add a present_func tag to your update block
BLTUpdateCallbacks = {}

function BLTUpdateCallbacks.blt_can_update_dll(update)
	return io.file_is_readable(update.present_file)
end

function BLTUpdateCallbacks.blt_get_dll_version()
	return (blt and blt.blt_version and blt.blt_version()) or "0.0.0.0"
end