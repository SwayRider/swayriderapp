# Auth Flows

## Login Flow

These are the various login and auth related flows for the mobile app.

### Notes

- Color scheme: @swayrider-app/design/color-scheme.md
- When a passowrd is set, the user always needs to confirm the password in a second input field

### Actors

- User
- Mobile App
- AuthService

### Scenarios

#### Existing User

1. User opens the Mobile App
2. The mobile app checks it's storage for a JWT / Refresh token
3. If no JWT is found, the app prompts the user to login
4. If a JWT is found, the app validates the JWT token to the AuthService
5. If the JWT is valid, the app redirects the user to the home page
6. If the JWT is invalid, the app tries to refresh the JWT token using the refresh token
7. If the refresh token is valid, the app redirects the user to the home page
8. If the refresh token is invalid, the app prompts the user to login
9. If the user is authenticated, the app redirects the user to the home page
10. If the user needs to login, he provides his email and password.
11. The Mobile App sends the email address and password to the AuthService
12. The AuthService sends a JWT token to the Mobile App
13. The Mobile App stores the JWT token and refresh token and redirects the user to the home page

#### New User

1. User opens the Mobile App
2. The Mobile App has no stored JWT / refresh token
3. The Mobile App prompts the user to login
5. The user selects the Signup option
6. The Mobile App prompts the user to enter their email address and password
7. The Mobile App sends the email address and password to the AuthService
8. The AuthService sends a confirmation email to the users with a deep link to the Mobile App
9. The Mobile App prompts the user to check it's email inbox
10. The user clicks on the confirmation link
11. The Mobile App opens the deep link and sends the confirmation token to the AuthService
12. The AuthService validates the confirmation token, the mobile app shows the verrified page with a button to go to the login screen (User can proceed with **Existing User** flow)
13. If the authservice denies the token, the mobile app prompts shows an error message and a button to go to the login screen.

#### Existing Unverified User

This follows the **Existing User** login. The only difference is that when the
mobile app detects the user is not verrified yet, it redirects to the verify page instead of to the home page, where it triggers a verification email to be send to the user.

#### Reset Password

1. User opens the Mobile App
2. User tries to login but fails
3. The Mobile App shows the login page again with an error message and shows the**Reset Password** option as an extra option on the page
4. The user selects the **Reset Password** option
5. The Mobile App prompts the user to enter their email address
6. The Mobile App sends the email address to the AuthService
7. The AuthService sends a reset password email to the users with a deep link to the Mobile App
8. The Mobile App prompts the user to check it's email inbox
9. The user clicks on the reset password link
10. The Mobile App opens the deep link and sends the reset password token to the AuthService
11. The AuthService validates the reset password token, the mobile app shows the choose new password page.
12. The user enters a new password
13. The Mobile App sends the new password to the AuthService.
14. The Mobile App shows the Password Changed confirmation page with a login button
15. The user can now login using the new password.

#### Change Password

1. The user opens the app and logs in
2. The user clicks on the profile icon on the top of the app bar and selects the 'profile' option
3. The mobile app shows the profile page and a Change Password button
4. The user clicks on the Change Password button
5. The mobile app shows the change password page with an input for the old password and inputs for a new password
6. The user enters the old password
7. The user enters the new password
8. The user enters the new password again
9. The user clicks on the Change Password button
10. The mobile app sends the new password to the AuthService
11. The mobile app shows the Password Changed confirmation page with a login button
12. The user can now login using the new password

   
