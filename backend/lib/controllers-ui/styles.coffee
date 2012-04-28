
module.exports = styles =

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

  '#mainwindow #snippetLabelField':
    'hyperlink-url': "http://help.livereload.com/kb/general-use/browser-extensions"
    'hyperlink-color': "#000a89"


for id in ['#nameTextField', '#pathTextField', '#statusTextField', '#addProjectButton', '#removeProjectButton', '#gettingStartedIconView', '#gettingStartedLabelField', '#terminalButton']
  styles["#mainwindow #{id}"] =
    'cell-background-style': 'raised'
