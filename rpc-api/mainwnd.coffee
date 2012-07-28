
_selectedProject = null

createWelcomeViewModel = ->
  pane: 'welcome'

createProjectViewModel = ->
  pane: 'project'
  name: _selectedProject.name

createViewModel = ->
  if _selectedProject is null
    createWelcomeViewModel()
  else
    createProjectViewModel()

publishViewModel = ->
  LR.client.mainwnd.rpane.setData(createViewModel())

exports.setSelectedProject = ({ projectId }, callback) ->
  if project = LR.projects.findById(projectId)
    _selectedProject = project
  else
    _selectedProject = null
  publishViewModel()
  callback(null)
