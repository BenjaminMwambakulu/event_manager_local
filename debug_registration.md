# Registration Fix Summary

## The Problem
The error was: `insert or update on table "attendee" violates foreign key constraint "attendee_user_id_fkey"`

This happened because:
1. The `attendee` table expects `user_id` to reference the `profiles` table
2. We were using Supabase auth `user.id` directly
3. The auth `user.id` didn't have a corresponding record in `profiles`

## The Solution

### 1. **Profile ID Lookup**
- Added `_getUserProfileId()` method to get the profile ID from auth user ID
- Looks up the profile using `user_id` field in profiles table

### 2. **Auto Profile Creation**
- If no profile exists, automatically creates one with:
  - `user_id`: Supabase auth user ID
  - `username`: Derived from email (before @)
  - `email`: User's email
  - `role`: Default to 'customer'

### 3. **Better Error Handling**
- Specific error messages for foreign key constraints
- Handles duplicate registration attempts
- Proper error propagation from EventService

### 4. **Updated Registration Flow**
```dart
// Before (broken)
await _eventService.registerToEvent(event.id, user.id, ticket.id);

// After (fixed)
final profileId = await _getUserProfileId(user.id);
await _eventService.registerToEvent(event.id, profileId, ticket.id);
```

## Database Schema Assumption
The fix assumes your `profiles` table has:
- `id` (primary key)
- `user_id` (references Supabase auth users)
- `username`
- `email`
- `role`

## Testing
1. Try registering for an event
2. Check if profile gets created automatically
3. Verify registration works without foreign key errors

## Next Steps
If you still get errors, check:
1. Your `profiles` table structure
2. RLS (Row Level Security) policies
3. User permissions for inserting into `profiles` and `attendee` tables