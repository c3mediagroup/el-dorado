# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper  
  
  protected
  
  def random_header_css
    image_files = %w( .jpg .gif .png )
    files = Dir.entries("#{HEADERS_FULL_PATH}").delete_if { |x| !image_files.index(x[-4,4]) }
    return '<style type="text/css">.header { background-image: url("'+HEADERS_PATH+files[rand(files.length)]+'"); }</style>'
  end

  def page_title
    if @topic && (current_action != "new")
      h(@topic.title) + " (" + h(SITE_TITLE) + ")"
    elsif @user && (current_action != "new") && logged_in?
      h(@user.login) + " (" + h(SITE_TITLE) + ")"
    else
      h(SITE_TITLE)
    end
  end
  
  def newbie
    @newbie = Newbie.find(:first, :order => "RAND()")
    return "Newest User" if @newbie.nil?
    return h(@newbie.term)
  end
  
  def avatar_img(user)
    image_tag AVATARS_PATH + h(user.avatar) unless user.avatar.blank?
  end
  
  def rank_for(posts_count)
    @rank = Ranks.find(:first, :order => "min_posts desc", :conditions => ["? >= min_posts", posts_count])
    return "Member" if @rank.nil?
    return h(@rank.title)
  end
  
  def tab(name)
    if name == current_controller
      'tab'
    elsif name == "topics" && (current_controller == "posts")
      'tab'
    end
  end
    
  def current_controller
    request.path_parameters['controller']
  end
  
  def current_action
    request.path_parameters['action']
  end
    
end
