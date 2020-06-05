module HomeHelper
  def get_covid_search_back_link_path
    if @folder && @folder!=""
      return "/drive_search?get_parent_files=true&folder=" + @folder
    elsif @query && @query!=""
      return "/drive_search"
    end
    return back_link_path = "/"
  end
end
