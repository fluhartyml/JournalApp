//XcodeFixInstructions
# Xcode Fix Instructions — Journal App (Option B only)

Last updated: 2025-09-16

Goal: Fix “Multiple commands produce …/Info.plist” and prevent camera-related crashes by using ONE custom Info.plist with required privacy keys.

## Do these steps, in order
1) Target → Build Settings → Packaging
   - Generate Info.plist File = No
   - Info.plist File = Journal App/Info.plist (or your exact relative path)
2) Target → Build Phases → Copy Bundle Resources
   - Ensure Info.plist is NOT listed
3) Project Navigator
   - Search for “Info.plist”. If you see more than one under the app target’s folders, remove extras from the project (move to Trash if unneeded)
4) Open your custom Info.plist and add these keys (Type = String):
   - NSCameraUsageDescription: "We use the camera to scan documents and attach them to your journal entries."
   - NSPhotoLibraryUsageDescription (if importing): "We access your photo library so you can import images into your journal."
   - NSPhotoLibraryAddUsageDescription (if saving): "We save images to your photo library when you export or share entries."
   - NSMicrophoneUsageDescription (if recording audio): "We use the microphone to record audio notes for your entries."
5) Product → Clean Build Folder (Cmd+Shift+K), then Build (Cmd+B)

## Verify
- Build succeeds with no “duplicate output Info.plist” error
- Launch on device → accessing camera no longer crashes

## If issues persist
- Build Settings → Levels: ensure only one definition of INFOPLIST_FILE for this target (and correct path)
- Other targets (Tests/UI Tests/Extensions): each must have its own Info.plist strategy (generate OR file), not both
- No Run Script phases should write an Info.plist into the same build location
