# Scrumbler - Add scrum functionality to any Redmine installation
# Copyright (C) 2011 256Mb Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class ScrumblerSprintsController < ScrumblerAbstractController
  unloadable

  before_filter :find_scrumbler_sprint
  before_filter :authorize, :only => [:settings, :update_general, :update_trackers, :update_issue_statuses]
  
  helper :scrumbler_sprints
  include ScrumblerSprintsHelper
  
  helper :scrumbler
  include ScrumblerHelper


  def settings
    @trackers = @project.trackers
    @issue_statuses = IssueStatus.all
    
    # Hashes
    @enabled_trackers = @scrumbler_sprint.trackers
    @enabled_statuses = @scrumbler_sprint.issue_statuses
  end
  
  def update_general
    @version = @scrumbler_sprint.version
    flash[:error] = t :error_scrumbler_general_update unless @version.update_attributes(params[:scrumbler_sprint]) 
          
    flash[:notice] = t :notice_successful_update unless flash[:error]
    redirect_to project_scrumbler_sprint_settings_url(@project, @scrumbler_sprint, :general)
  end
  
  def update_trackers
    params[:scrumbler_sprint][:scrumbler_sprint_trackers].delete_if { |k, v|  !v[:enabled]}
    @scrumbler_sprint.settings[:trackers] = params[:scrumbler_sprint][:scrumbler_sprint_trackers]
    
    flash[:error] = t :error_scrumbler_trackers_update unless @scrumbler_sprint.save 
          
    flash[:notice] = t :notice_successful_update unless flash[:error]
    redirect_to project_scrumbler_sprint_settings_url(@project, @scrumbler_sprint, :trackers)
  end
  
  def update_issue_statuses
    #TODO
    params[:scrumbler_issue_statuses].delete_if { |k, v|  !v[:enabled]}
    @scrumbler_sprint.settings[:issue_statuses] =  params[:scrumbler_issue_statuses]
    flash[:error] = t :error_scrumbler_trackers_update unless @scrumbler_sprint.save
      
    flash[:notice] = t :notice_successful_update unless flash[:error]
    redirect_to project_scrumbler_sprint_settings_url(@project, @scrumbler_sprint, :issue_statuses)
  end
  
  def update_issue
    @issue = Issue.find(params[:issue_id])
    @message = if @issue.new_statuses_allowed_to(User.current).map(&:id).include?(params[:issue][:status_id].to_i)
      if @issue.update_attributes(params[:issue])
        {:success => true, :sprint_name => @scrumbler_sprint.name_with_points}
      else
        {:success => false}
      end
    else
      new_status = IssueStatus.find(params[:issue][:status_id])
      {:success => false, :text => l(:error_scrumbler_issue_status_change, :status_name => new_status.name)}
    end

    render :json => @message
  end
  
  def change_issue_assignment_to_me
    @issue = Issue.find(params[:issue_id])
    @issue.assigned_to = User.current
    render :json => {:success => @issue.save, :issue => issue_for_json(@issue)}
  end
  
  def drop_issue_assignment
    @issue = Issue.find(params[:issue_id])
    if @issue.assigned_to == User.current
      @issue.assigned_to = nil
      render :json => {:success => @issue.save, :issue => issue_for_json(@issue)}
    else
      render :status => 403
    end
  end
  
  private
  def find_scrumbler_sprint
    @scrumbler_sprint = @project.scrumbler_sprints.find(params[:id])
  end
  
end
