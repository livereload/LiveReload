
module.exports =

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
