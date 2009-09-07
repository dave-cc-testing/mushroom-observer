require File.dirname(__FILE__) + '/../test_helper'
require 'account_controller'

# Raise errors beyond the default web-based presentation
class AccountController; def rescue_action(e) raise e end; end

class AccountControllerTest < Test::Unit::TestCase

  fixtures :users
  fixtures :images
  fixtures :licenses
  fixtures :locations

  def setup
    @controller = AccountController.new
    @request, @response = ActionController::TestRequest.new, ActionController::TestResponse.new
    @request.host = "localhost"
  end

  def teardown
    if File.exists?(IMG_DIR)
      FileUtils.rm_rf(IMG_DIR)
    end
  end

  def test_auth_rolf
    @request.session['return-to'] = "http://localhost/bogus/location"

    post :login, "user_login" => "rolf", "user_password" => "testpassword"
    assert(@response.has_session_object?(:user_id))

    assert_equal @rolf.id, @response.session[:user_id]

    assert_equal("http://localhost/bogus/location", @response.redirect_url)
  end

  def test_signup
    @request.session['return-to'] = "http://localhost/bogus/location"

    post :signup, "new_user" => { "login" => "newbob", "password" => "newpassword", "password_confirmation" => "newpassword",
                              "email" => "nathan@collectivesource.com", "mailing_address" => "", "theme" => "NULL", "notes" => "" }
    assert(@response.has_session_object?(:user_id))

    assert_equal("http://localhost/bogus/location", @response.redirect_url)
  end

  def test_bad_signup
    @request.session['return-to'] = "http://localhost/bogus/location"

    # Password doesn't match
    post :signup, "new_user" => { "login" => "newbob", "password" => "newpassword", "password_confirmation" => "wrong",
      "mailing_address" => "", "theme" => "NULL", "notes" => "" }
    assert(@response.template_objects["new_user"].errors.invalid?(:password))

    # No email
    post :signup, "new_user" => { "login" => "yo", "password" => "newpassword", "password_confirmation" => "newpassword",
      "mailing_address" => "", "theme" => "NULL", "notes" => "" }
    assert(@response.template_objects["new_user"].errors.invalid?(:login))

    # Bad password and no email
    post :signup, "new_user" => { "login" => "yo", "password" => "newpassword", "password_confirmation" => "wrong",
      "mailing_address" => "", "theme" => "NULL", "notes" => "" }
    assert(@response.template_objects["new_user"].errors.invalid?(:password))
    assert(@response.template_objects["new_user"].errors.invalid?(:login))
  end

  def test_signup_theme_errors
    @request.session['return-to'] = "http://localhost/bogus/location"

    post :signup, "new_user" => { "login" => "spammer", "password" => "spammer", "password_confirmation" => "spammer",
                              "email" => "spam@spam.spam", "mailing_address" => "", "theme" => "", "notes" => "" }
    assert(!@response.has_session_object?("user"))

    # Disabled denied email in above case...
    # assert_equal("http://localhost/bogus/location", @response.redirect_url)

    post :signup, "new_user" => { "login" => "spammer", "password" => "spammer", "password_confirmation" => "spammer",
                              "email" => "spam@spam.spam", "mailing_address" => "", "theme" => "spammer", "notes" => "" }
    assert(!@response.has_session_object?("user"))
    assert_redirected_to(:controller => "account", :action => "welcome")
  end

  def test_invalid_login
    post :login, "user_login" => "rolf", "user_password" => "not_correct"

    assert(!@response.has_session_object?("user"))

    assert(@response.has_template_object?("login"))
  end

#   def test_login_logoff
#
#     post :login, "user_login" => "rolf", "user_password" => "testpassword"
#     assert(@response.has_session_object?("user"))
#
#     get :logout_user
#     assert(!@response.has_session_object?("user"))
#
#   end

  # Test autologin feature.
  def test_autologin
    #
    # First make sure test page that requires login fails without autologin cookie.
    get :test_autologin
    assert_response :redirect
    #
    # Make sure cookie is not set if clear remember_me box in login.
    post :login, {
      "user_login"    => "rolf",
      "user_password" => "testpassword",
      :user => { :remember_me => "" }
    }
    assert session[:user_id]
    assert !cookies[:mo_user]
    session[:user_id] = nil
    get :test_autologin
    assert_response :redirect
    #
    # Now clear session and try again with remember_me box set.
    post :login, {
      "user_login"    => "rolf",
      "user_password" => "testpassword",
      :user => { :remember_me => "1" }
    }
    assert session[:user_id]
    assert cookies['mo_user']
    #
    # And make sure autlogin will pick that cookie up and do its thing.
    session[:user_id] = nil
    @request.cookies['mo_user'] = cookies['mo_user']
    get :test_autologin
    assert_response :success
  end

  def test_edit_prefs
    # First make sure it can serve the form to start with.
    requires_login(:prefs)
    # Now change everything.
    params = {
      :user => {
        :login             => "new_login",
        :email             => "new_email",
        :theme             => "Agaricus",
        :notes             => "",
        :mailing_address   => "",
        :license_id        => "1",
        :rows              => "10",
        :columns           => "10",
        :alternate_rows    => "",
        :alternate_columns => "",
        :vertical_layout   => "",
        :email_comments_owner         => "1",
        :email_comments_response      => "1",
        :email_comments_all           => "",
        :email_observations_consensus => "1",
        :email_observations_naming    => "1",
        :email_observations_all       => "",
        :email_names_author           => "1",
        :email_names_editor           => "",
        :email_names_reviewer         => "1",
        :email_names_all              => "",
        :email_locations_author       => "1",
        :email_locations_editor       => "",
        :email_locations_all          => "",
        :email_general_feature        => "1",
        :email_general_commercial     => "1",
        :email_general_question       => "1",
        :email_digest                 => "immediately",
        :email_html                   => "1",
      }
    }
    post_with_dump(:prefs, params)
    assert_equal(:prefs_success.t, flash[:notice])
    # Make sure changes were made.
    user = @rolf .reload
    assert_equal("new_login",  user.login)
    assert_equal("new_email",  user.email)
    assert_equal("Agaricus",   user.theme)
    assert_equal(@ccnc25,      user.license)
    assert_equal(10,           user.rows)
    assert_equal(10,           user.columns)
    assert_equal(false,        user.alternate_rows)
    assert_equal(false,        user.alternate_columns)
    assert_equal(false,        user.vertical_layout)
    assert_equal(true,         user.email_comments_owner)
    assert_equal(true,         user.email_comments_response)
    assert_equal(false,        user.email_comments_all)
    assert_equal(true,         user.email_observations_consensus)
    assert_equal(true,         user.email_observations_naming)
    assert_equal(false,        user.email_observations_all)
    assert_equal(true,         user.email_names_author)
    assert_equal(false,        user.email_names_editor)
    assert_equal(true,         user.email_names_reviewer)
    assert_equal(false,        user.email_names_all)
    assert_equal(true,         user.email_locations_author)
    assert_equal(false,        user.email_locations_editor)
    assert_equal(false,        user.email_locations_all)
    assert_equal(true,         user.email_general_feature)
    assert_equal(true,         user.email_general_commercial)
    assert_equal(true,         user.email_general_question)
    assert_equal(:immediately, user.email_digest)
    assert_equal(true,         user.email_html)
  end

  def test_edit_prefs_login_already_exists
    params = {
      :user => {
        :login => "mary",
        :email => "email", # (must be defined or will barf)
      }
    }
    post_requires_login(:prefs, params)
  end

  def test_edit_profile
    # First make sure it can serve the form to start with.
    requires_login(:profile)
    # Now change everything.
    params = {
      :user => {
        :name       => "new_name",
        :notes      => "new_notes",
        :place_name => "Burbank, Los Angeles Co., California, USA",
        :mailing_address => ""
      }
    }
    post_with_dump(:profile, params)
    assert_equal(:profile_success.t, flash[:notice])
    # Make sure changes were made.
    user = @rolf.reload
    assert_equal("new_name", user.name)
    assert_equal("new_notes", user.notes)
    assert_equal(@burbank, user.location)
  end

  # Test uploading mugshot for user profile.
  def test_add_mugshot
    # Create image directory and populate with test images.
    FileUtils.cp_r(IMG_DIR.gsub(/test_images$/, 'setup_images'), IMG_DIR)
    # Open file we want to upload.
    file = FilePlus.new("test/fixtures/images/sticky.jpg")
    file.content_type = 'image/jpeg'
    # It should create a new image: this is the ID it should use.
    new_image_id = Image.find(:all).last.id + 1
    # Post form.
    params = {
      :user => {
        :upload_image => file,
        :name         => @rolf.name,
        :mailing_address => @rolf.mailing_address,
        :notes        => ""
      },
      :date => { :copyright_year => "2003" },
      :upload => { :license_id => @ccnc25.id },
      :copyright_holder => "Someone Else",
    }
    post_requires_login(:profile, params, false)
    # assert_redirected_to(:controller => "account", :action => "welcome")
    @rolf.reload
    assert_equal(new_image_id, @rolf.image_id)
    assert_equal("Rolf Singer", @rolf.image.title)
    assert_equal("Someone Else", @rolf.image.copyright_holder)
    assert_equal(2003, @rolf.image.when.year)
    assert_equal(@ccnc25, @rolf.image.license)
  end

  def no_email_hooks_helper(type)
    post_requires_login("no_email_#{type}".to_sym, { :id => @rolf.id }, false)
    assert_response(:success)
    assert_template('no_email')
    @rolf.reload
    assert(!@rolf.send("email_#{type}"))
    logout
  end

  def test_no_email_hooks
    no_email_hooks_helper(:comments_owner)
    no_email_hooks_helper(:comments_response)
    no_email_hooks_helper(:comments_all)
    no_email_hooks_helper(:observations_consensus)
    no_email_hooks_helper(:observations_naming)
    no_email_hooks_helper(:observations_all)
    no_email_hooks_helper(:names_author)
    no_email_hooks_helper(:names_editor)
    no_email_hooks_helper(:names_reviewer)
    no_email_hooks_helper(:names_all)
    no_email_hooks_helper(:locations_author)
    no_email_hooks_helper(:locations_editor)
    no_email_hooks_helper(:locations_all)
    no_email_hooks_helper(:general_feature)
    no_email_hooks_helper(:general_commercial)
    no_email_hooks_helper(:general_question)
  end
end
