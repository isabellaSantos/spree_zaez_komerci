def sign_in_admin!(user)
  visit '/admin'
  fill_in 'Email', with: user.email
  fill_in 'Password', with: user.password
  click_button 'Login'
end

def create_admin_and_sign_in
  @admin = create(:admin_user)
  sign_in_admin! @admin
end