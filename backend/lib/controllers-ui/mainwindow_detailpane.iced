
module.exports = class DetailPaneController

  initialize: ->
    @$
      '#projectPane':
        placeholder: '#panePlaceholder'
        visible: yes

      '#nameTextField':
        text: 'Foo'

      '#pathTextField':
        text: 'Bar'

      # just for a test
      '#statusTextField':
        text: "Hello from DetailPaneController"

  setProject: (project) ->
    @$
      '#nameTextField':
        text: project.name

      '#pathTextField':
        text: project.path
