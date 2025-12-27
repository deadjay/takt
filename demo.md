# Takt App Demo Guide

## Testing the App

### 1. Build and Run
1. Open `Takt.xcodeproj` in Xcode 15.0+
2. Select your development team in project settings
3. Build and run on iOS 18.0+ device or simulator

### 2. Testing Image Processing
1. **Photo Library Test**:
   - Take a screenshot of a calendar event or meeting invitation
   - In the app, go to Import tab → Photo Library
   - Select the screenshot
   - Tap "Extract Event Details"
   - Verify text extraction and event parsing

2. **Camera Test**:
   - In the app, go to Import tab → Camera
   - Take a photo of a document with event information
   - Tap "Extract Event Details"
   - Verify OCR functionality

3. **Clipboard Test**:
   - Copy an image with text to clipboard
   - In the app, go to Import tab → Paste from Clipboard
   - Verify image import

### 3. Testing Event Management
1. **Add Extracted Event**:
   - After extracting an event, tap "Add to Calendar"
   - Verify event appears in Calendar and Events tabs

2. **Manual Event Creation**:
   - Go to Events tab → tap "+" button
   - Fill in event details (name, date, deadline, notes)
   - Tap "Add Event"
   - Verify event appears in all views

3. **Event Editing**:
   - Tap on any event to view details
   - Tap "Edit Event" to modify details
   - Verify changes are saved

4. **Event Completion**:
   - In event details, tap "Mark as Completed"
   - Verify status changes and visual indicators

### 4. Testing Calendar View
1. **Monthly Navigation**:
   - Use left/right arrows to navigate months
   - Verify event indicators on dates with events

2. **Date Selection**:
   - Tap on different dates
   - Verify events for selected date are displayed

3. **Event Details**:
   - Tap on event rows to view full details
   - Verify all event information is displayed correctly

### 5. Testing Search and Filter
1. **Event Search**:
   - Go to Events tab
   - Use search bar to find events by name or notes
   - Verify filtering works correctly

2. **Event Deletion**:
   - Swipe left on events in the list
   - Tap delete button
   - Verify events are removed

### 6. Testing Offline Functionality
1. **Turn off WiFi/Cellular**:
   - Verify app continues to work
   - Add/edit/delete events
   - Verify data persistence

2. **App Restart**:
   - Close and reopen the app
   - Verify all events are still present
   - Verify calendar state is maintained

## Sample Test Images

### Good Test Cases:
1. **Meeting Invitation**:
   ```
   Team Standup Meeting
   Date: Dec 25, 2024
   Time: 9:00 AM
   Deadline: Dec 24, 2024
   ```

2. **Event Flyer**:
   ```
   Holiday Party
   December 25, 2024
   RSVP by: Dec 20, 2024
   ```

3. **Calendar Screenshot**:
   ```
   Project Deadline
   12/31/2024
   Submit final report
   ```

### Edge Cases to Test:
1. **Poor Image Quality**: Blurry or low-resolution images
2. **Complex Layouts**: Images with multiple columns or overlapping text
3. **Different Date Formats**: Various international date formats
4. **Mixed Languages**: Images with text in different languages
5. **No Text**: Images without any text content

## Expected Behavior

### Text Recognition:
- Should extract all visible text from images
- Should handle various font sizes and styles
- Should work with both light and dark text on different backgrounds

### Event Parsing:
- Should identify event names (usually first meaningful line)
- Should recognize multiple date formats
- Should distinguish between event date and deadline
- Should handle time information when present

### Data Persistence:
- Events should be saved immediately
- App should remember state between sessions
- Data should persist through app updates

### User Experience:
- UI should be responsive and intuitive
- Error messages should be clear and helpful
- Loading states should provide feedback
- Navigation should be smooth and logical

## Troubleshooting

### Common Issues:
1. **Camera Permission Denied**: Check Info.plist and device settings
2. **Photo Library Access**: Verify privacy permissions
3. **Text Recognition Fails**: Check image quality and text clarity
4. **Events Not Saving**: Verify EventStorageService is working
5. **UI Not Updating**: Check @StateObject and @Published properties

### Debug Tips:
1. Check Xcode console for error messages
2. Verify all required frameworks are linked
3. Test on different device types and orientations
4. Verify deployment target compatibility
5. Check Info.plist permissions are correct

## Performance Testing

### Memory Usage:
- Monitor memory usage during image processing
- Check for memory leaks with large images
- Verify proper cleanup of image resources

### Processing Speed:
- Test with various image sizes
- Verify UI remains responsive during processing
- Check processing time scales appropriately

### Battery Impact:
- Monitor battery usage during camera usage
- Verify efficient text recognition processing
- Check background task handling


