# Widget & Live Activity Setup Instructions

## Step 1: Add Widget Extension Target

1. In Xcode, go to **File > New > Target**
2. Select **Widget Extension**
3. Name it: `dayaWidget`
4. Uncheck "Include Configuration Intent"
5. Click Finish

## Step 2: Add Live Activity Target

1. Go to **File > New > Target**
2. Select **Widget Extension** again
3. Name it: `dayaLiveActivity`
4. Uncheck "Include Configuration Intent"
5. Click Finish

## Step 3: Enable App Groups

1. Select your **main app target** (daya)
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **App Groups**
5. Click **+** and add: `group.com.daya.app`

6. Repeat for **dayaWidget** target
7. Repeat for **dayaLiveActivity** target

## Step 4: Replace Widget Code

1. Delete the default widget code in `dayaWidget/dayaWidget.swift`
2. Copy the code from the new `dayaWidget.swift` file I created
3. Update `Info.plist` with the one I provided

## Step 5: Replace Live Activity Code

1. Delete the default code in `dayaLiveActivity/dayaLiveActivity.swift`
2. Copy the code from the new `dayaLiveActivity.swift` file I created

## Step 6: Enable Live Activities in Info.plist

1. Open your main app's **Info.plist**
2. Add new key: `NSSupportsLiveActivities` (Boolean) = YES

## Step 7: Update Schemes

1. Edit scheme for main app
2. Make sure widget and live activity targets are included in build

## Step 8: Test

### Widget:
1. Run the app on a device/simulator
2. Long press home screen > Add Widget > Find "Daya"
3. Select the medium widget

### Live Activity:
1. Run the app
2. Mark one task (not both)
3. Lock your phone
4. Should see the live activity on lock screen
5. Complete both tasks → activity disappears

## Notes

- Widgets update at midnight automatically
- Live Activity starts when you have incomplete tasks
- Live Activity ends when both tasks are complete
- All data syncs via App Groups (group.com.daya.app)

