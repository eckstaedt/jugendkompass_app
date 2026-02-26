

## Problem Analysis

The issue is a race condition between the AuthContext and DashboardLayout:

1. **AuthContext's `onAuthStateChange`** fires (e.g., on token refresh), calls `setUser(customUser)` immediately, but `isAdmin` remains `false` until the async `checkAdminStatus` resolves inside `setTimeout(..., 0)`.
2. **DashboardLayout's `useEffect`** sees `loading=false`, `user=set`, `isAdmin=false` during that brief window and redirects to `/login`.
3. The `title` prop in the DashboardLayout effect's dependency array causes the effect to re-run on every page navigation, amplifying the problem.

## Plan

### 1. Fix DashboardLayout useEffect
- Remove `title` from the dependency array (it's irrelevant to auth).
- Only redirect when `isAdmin` is definitively `false` after loading completes. Don't redirect if user exists but admin status hasn't been confirmed yet.

### 2. Add `adminChecked` state to AuthContext
- Add a boolean `adminChecked` state (default `false`) that is set to `true` only after the admin check completes.
- Expose it alongside `loading` so DashboardLayout can wait for both `!loading && adminChecked` before making redirect decisions.
- In the `onAuthStateChange` handler, set `adminChecked = false` before the async check starts, and `true` after it resolves.

### Files to modify
- `src/contexts/AuthContext.tsx` — add `adminChecked` state, expose it
- `src/components/layouts/DashboardLayout.tsx` — use `adminChecked`, remove `title` from deps

