# CellEditor - Tool for editing all the aspects of a Cell
#	in one Toplevel, using tables mostly.
#
# PJM 2005-09-05	Begun, based on Poet's ObjectEditorTool
# PJM 2006-02-18	Rearranged layout, removed seperate tree and table paths
#					-tool is now set on subordinate widgets
# PJM 2006-02-28	Navigation controlled by NavBar via ``navigate``
# PJM 2006-05-04	Alternate view support begun, at time of construction only
# PJM 2006-09-18	Modifications to use paramList begun
# PJM 2007-05-07	EditBar added
# PJM 2007-08-28	Wave added
# PJM 2007-11-30	Wave moved to Space (one global editing wave, not one per
#					CellEditor).
#


Window construct CellEditor
CellEditor mixin CellObserver
CellEditor mixin ParamListOwner

#CellEditor slot isModified 0			;# true if cell has been modified

# Options that must be specified at creation time
CellEditor slot extraOptions {view paramList}

# The list cell that contains our parameters
#
CellEditor slot paramList {}

#  Observer handler methods
#
CellEditor method newPath {target event} {
	set path [$target get]

	if {![$self pathDelta $path]} return

	$self wm title "$path ([$self viewCell])"
}

# Build the primary for a CellEditor
# We pick up _mainframe from MainFrameTool
#
CellEditor method buildPrimary {} {
	$self destroyPrimary

	# File selector for import/export
	$self slot _filesel [Fileselector construct * -dir [pwd] -ext "3rd"]

	# Defaults for menu options (the first two are toolbar slots, special-cased below)
	$self slot _showNav [$self getParam showNavBar] 
	$self slot _showEdit [$self getParam showEditBar] 
	$self slot _showTriad [$self getParam showTriadBar]
	$self slot> _showTypes [$self getParam showTypes] {$self setParam showTypes $value}
	$self slot> _showTree [$self getParam showTree] {$self setParam showTree $value}

	$self slot> _showPanels [$self getParam panels] \
		{$self setParam panels $value}
	$self slot> _gridPanels [$self getParam gridpanels] \
		{$self setParam gridpanels $value}
	$self slot> _defaultGPanel [$self getParam defaultGpanel] \
		{$self setParam defaultGpanel $value}
	$self slot> _defaultCPanel [$self getParam defaultCpanel] \
		{$self setParam defaultCpanel $value}


	$self slot> _showIFrame [string toupper [$self getParam iframe] 0 0] \
		{$self setParam iframe [string tolower $value]}
	$self slot> _showJFrame [string toupper [$self getParam jframe] 0 0] \
		{$self setParam jframe [string tolower $value]}
	$self slot> _layout [string toupper [$self getParam layout] 0 0] \
		{$self setParam layout [string tolower $value]}
	$self slot> _iDirection [string toupper [$self getParam idirection] 0 0] \
		{$self setParam idirection [string tolower $value]}

    $self slot menu [list "&Cell" all object 1]
    $self slotAppend menu [format {
            {command "&Refresh" {} "Refresh view" {} -command "%s refresh"}
            {command "&Unselect All" {} "Clear the cell selection" {} -command "%s clearSelection"}
			{separator}
            {command "&Go to Root" {} "Go to the root cell (/)" {} -command "%s setPath /"}
            {command "Set as &Home" {} "Set this cell as the home for this editor" {} -command "%s setHome"}
			{separator}
			{command "&Import" {} "Import from file" {} -command "%s import"}
			{command "&Export" {} "Export to file" {} -command "%s export"}
			{separator}
            {command "&Close" {} "Close this window" {} -command "%s destruct"}
        } $self $self $self $self $self $self $self]

            # removed  {checkbutton "T&ree" {all option} "Show/hide tree pane" {} -variable %s}
	$self slotAppend menu "&View" all options 1
	$self slotAppend menu [format {
            {checkbutton "&Triad Toolbar" {all option} "Show/hide triad toolbar" {} -variable %s}
            {checkbutton "&Navigation Toolbar" {all option} "Show/hide navigation toolbar" {} -variable %s}
            {checkbutton "&Edit Toolbar" {all option} "Show/hide editing toolbar" {} -variable %s}
			{separator}
            {checkbutton "Show types" {all option} "Show/hide type icons in lower right corner of each cell" {} -variable %s}
			{separator}
			{cascade "Panels" {} panels 1 {
				{checkbutton "Panels" {all option} "Show/hide panels" {} -variable %s}
				{checkbutton "Grid Panels" {all option} "Prefer grid panels over cell panels" {} -variable %s}
				{cascade "Default Grid Panel" {} defgpanel 0 {
					{radiobutton none {} "No default grid panel is used" {} -variable %s}
					{radiobutton table {} "Use table panel for grids" {} -variable %s}
					{radiobutton "read-only table" {} "Use read-only table panel for grids" {} -variable %s}
					}
				}
				{cascade "Default Cell Panels" {} defcpanel 0 {
					{radiobutton none {} "No default cell panels are used" {} -variable %s}
					{radiobutton "by type" {} "Default cell panels specific to each type" {} -variable %s}
					{radiobutton "text entries" {} "All cells paneled with text entry boxes" {} -variable %s}
					}
				}
				}
			}
			{cascade "Layout" {} layout 0 {
				{radiobutton Expand {} "Expand to fill width and height" {} -variable %s}
				{radiobutton Fixed {} "Fixed-sized cells" {} -variable %s}
				}
			}
			{cascade "i Direction" {} idirection 0 {
				{radiobutton Auto {} "i axis points right unless j = 1" {} -variable %s}
				{radiobutton Right {} "i axis always points right" {} -variable %s}
				{radiobutton Down {} "i axis always points down" {} -variable %s}
				}
			}
			{separator}
			{cascade "i Frame" {} iframe 0 {
				{radiobutton Auto {} "Show i frame if it contains values" {} -variable %s}
				{radiobutton Always {} "Always show i frame" {} -variable %s}
				{radiobutton Never {} "Never show i frame" {} -variable %s}
				}
			}
			{cascade "j Frame" {} jframe 0 {
				{radiobutton Auto {} "Show j frame if it contains values" {} -variable %s}
				{radiobutton Always {} "Always show j frame" {} -variable %s}
				{radiobutton Never {} "Never show j frame" {} -variable %s}
				}
			}
        } \
      [$self slotVar _showTriad] [$self slotVar _showNav] [$self slotVar _showEdit]   \
	  [$self slotVar _showTypes] \
	  [$self slotVar _showPanels] [$self slotVar _gridPanels] \
	  [$self slotVar _defaultGPanel] [$self slotVar _defaultGPanel] [$self slotVar _defaultGPanel] \
	  [$self slotVar _defaultCPanel] [$self slotVar _defaultCPanel] [$self slotVar _defaultCPanel] \
	  [$self slotVar _layout] [$self slotVar _layout] \
	  [$self slotVar _iDirection] [$self slotVar _iDirection] [$self slotVar _iDirection] \
	  [$self slotVar _showIFrame] [$self slotVar _showIFrame] [$self slotVar _showIFrame] \
	  [$self slotVar _showJFrame] [$self slotVar _showJFrame] [$self slotVar _showJFrame] \
	]


	set prim [$self as MainFrameTool buildPrimary]
	set mf [$self getFrame]
	set pl [$self slot paramList]
	assert {$pl ne ""}

	$self wm withdraw

	set path [$pl watchSub! $self newPath path]

	set tb [$self addToolBarSlot _showTriad 1]
	[$self slot _triadBar [TriadBar construct]] build $tb

	# Construct the navigation bar using ``addToolBarSlot``,
	# then augment the write method for the _showNav slot.
	#
	set nb [$self slot _navBar [NavBar new [$self addToolBarSlot _showNav [$self slot _showNav]] $pl]]
	$self methodAppend _showNav> {$self setParam showNavBar $value}

	# Similarly for the edit bar
	#
	set eb [$self slot _editBar [EditBar new [$self addToolBarSlot _showEdit [$self slot _showEdit]] $pl]]
	$self methodAppend _showEdit> {$self setParam showEditBar $value}

	switch [$self slot view] {
		tktable {
			set pw [BW_PanedWindow construct * $mf -side bottom \
				-layout {-side top -fill both -expand yes}]

			set fr [$pw add -weight 1]

			$self slot _tree [CellTreeBook construct * $fr -tool $self \
				-width 100 -paramList $pl \
				-layout {-side top -expand yes -fill both}]

			set fr [$pw add -weight 2]

			$self slot _table [CellTableBook construct * $fr -tool $self \
				-width 400 -paramList $pl \
				-layout {-side top -expand yes -fill both}]
		}
		zinc {
			$self slot _canvas [CellZincTable construct * $mf -tool $self \
				-paramList $pl -width 400 \
				-layout {-side top -expand yes -fill both}]
		}
	}

	$self addResizer

	$self wm deiconify

	$nb setHome $path
    update idletasks

	return $prim
}

# Destroy a CellEditor, destroying any component objects
#
CellEditor method destruct {} {
	Object safe [$self slot _filesel] destruct
	$self as [CellEditor parent] destruct
}

# When done resizing, make sure to render
#
CellEditor method resizeEnd {w rx ry} {
	$self as MainFrameTool resizeEnd $w $rx $ry
	[$self slot _canvas] renderRoot
}

# Navigate down to a subcell of what's currently displayed
#
CellEditor method navdown {c} {
	Object safe [$self slot _navBar] navdown $c
}

# Navigate up to the lowest common ancestor and down to ``c``
#
CellEditor method navupdown {c} {
	Object safe [$self slot _navBar] navupdown $c
}

# Jump to a cell (no animation)
#
CellEditor method jump {c} {
	Object safe [$self slot _navBar] setPath jump [$c path] yes yes
}

# Set the edit path, with a progress display.
#
CellEditor method setPath {p} {
	if {![$self pathDelta $p]} return

	$self progressRun {$self setParam path $p} "Inspecting $p ..." 
}

# Set the currently viewed path as the home
#
CellEditor method setHome {} {
	Object safe [$self slot _navBar] setHome
}

# Refresh both panes.  If clear is true, set both panes to viewing {}
#
CellEditor method refresh {{clear 0}} {
	if {$clear} {
		$self progressRun {$self setParam path {}} "Clearing display ..."
	} else {
		$self progressRun {$self triggerParam path} "Refreshing display ..."
	}
}

# Clear the selection
#
CellEditor method clearSelection {} {
	$self setParamIgnore selectGrid ""
	$self setParamIgnore select0 ""
	$self setParamIgnore select1 ""
	$self setParam selectmode none
}

# Import from a file
#
CellEditor method import {} {
	set fs [$self slot _filesel] 

	$fs slot title "Import from"
	set fn [$fs getOpen]
	if {$fn eq ""} return

	theSpace import [$self slot _cell] $fn
}

# Export to a file
#
CellEditor method export {} {
	set fs [$self slot _filesel] 

	$fs slot title "Export to"
	set fn [$fs getSave]
	if {$fn eq ""} return

	theSpace export [$self slot _cell] $fn
}
