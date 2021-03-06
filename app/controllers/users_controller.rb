class UsersController < ApplicationController
  before_action :set_user, only: [:edit, :update, :show, :destroy]
  before_action :require_same_user, only: [:edit, :update]

  #def index
    #@users = User.all
  #end

  def new
    @user = User.new
  end

    def create
      @user = User.new(allowed_params)
      @user.admin = false
      if params[:agreed_terms_of_service]
        if @user.save
          UserMailer.account_activation(@user).deliver_now
          flash[:notice] = "Thank you for signing up! Please check your email to activate account"
          redirect_to root_path
        else
          render 'new'
        end
      else
        flash[:danger] = "You need to read the terms and service."
        render 'new'
      end
  end

  def show
  end

  def edit
  end

  def update
    if @user.update(allowed_params)
      flash[:notice] = "Successfully edited"
      redirect_to user_path(@user)
    else
      render 'edit'
    end
  end

  def destroy
    @user.destroy
    flash[:notice] = "Deleted"
    redirect_to manage_website_path
  end

  def my_friends
    @friendships = current_user.friends
  end

  def my_followers
    @followers = Friendship.where(:friend_id => current_user.id).all
  end

  def search
    if params[:search_param].blank?
      flash[:notice] = "You have entered an empty search string"
    else
      @users = User.search(params[:search_param])
      @users = current_user.except_current_user(@users)
      flash[:notice] = "No users match this search criteria" if @users.blank?
    end
    render 'my_friends'
  end

  def add_friend
    @friend = User.find(params[:friend])
    #current_user.friendships.build(friend_id: @friend.id)

    #if current_user.save
    if current_user.friends << @friend
      flash[:notice] = "Friend was successfully added"
      send_notification('friend', 'new_follower', current_user, @friend, nil, nil)
    else
      flash[:danger] = "Friend was failed to be added"
    end
    redirect_to request.referrer
  end

  def add_follower
    @friend = User.find(params[:friend])
    #current_user.friendships.build(friend_id: @friend.id)

    #if current_user.save
    if current_user.friends << @friend
      flash[:notice] = "Friend was successfully added"
      send_notification('friend', 'new_follower', current_user, @friend, nil, nil)
    else
      flash[:danger] = "Friend was failed to be added"
    end
    redirect_to my_followers_path
  end

  def my_places
    @places = Place.where(user: current_user).order('created_at DESC')
  end

  def manage_website
    @users = User.all
    @items = Item.all
    @tags = Tag.all
  end

  def remove_admin
    User.find(params[:id_param]).update_attribute(:admin, false)
    redirect_to manage_website_path
  end

  def add_admin
    User.find(params[:id_param]).update_attribute(:admin, true)
    redirect_to manage_website_path
  end

  def setup_admin
    @users = User.all
  end

  def ini
    User.find(params[:id_param]).update_attribute(:admin, true)
    redirect_to root_path
  end


  # PRIVATE FUNCTIONS
  private

  def allowed_params
    params.require(:user).permit(:username, :email, :password, :password_confirmation)
  end

  def set_user
    @user = User.find(params[:id])
  end

  def require_same_user
    if current_user != @user
      flash[:danger] = "you can only edit or delete your own user"
      redirect_to users_path
    end
  end

end
