
module.exports = styles =

  '#mainwindow':
    'type': 'MainWindow'

  '#mainwindow #projectOutlineView':
    'style':           'source-list'
    'dnd-drop-types': ['file']
    'dnd-drag':         yes
    'cell-type':       'ImageAndTextCell'

  '#mainwindow #projectOutlineView data #folders':
    label: "MONITORED FOLDERS"
    'is-group': yes
    expanded: yes

  '#mainwindow #projectOutlineView data .project':
    image: 'folder'
    expandable: no

  '#mainwindow #welcomePane':
    placeholder: '#panePlaceholder'

  '#mainwindow #projectPane':
    placeholder: '#panePlaceholder'

  '#mainwindow #snippetLabelField':
    'hyperlink-url': "http://help.livereload.com/kb/general-use/browser-extensions"
    'hyperlink-color': "#000a89"


  '#monitoring':
    'type': 'MonitoringSettingsWindow'

  '#compilation':
    'type': 'CompilationOptionsWindow'
    'parent-window': '#mainwindow'
    'parent-style':  'sheet'

  '#postproc':
    'type': 'PostprocOptionsWindow'
    'parent-window': '#mainwindow'
    'parent-style':  'sheet'



for id in ['#nameTextField', '#pathTextField', '#statusTextField', '#addProjectButton', '#removeProjectButton', '#gettingStartedIconView', '#gettingStartedLabelField', '#terminalButton']
  styles["#mainwindow #{id}"] =
    'cell-background-style': 'raised'
