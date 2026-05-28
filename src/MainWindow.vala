/*
 * MainWindow.vala
 * 
 * Copyright 2015 Tony George <teejee2008@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 * 
 * 
 */
 
using Gtk;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.System;
using TeeJee.Misc;

public class MainWindow : Adw.ApplicationWindow {

	private Image img_preview;
	private Box vbox_main;
	private Box vbox_status;
	private Box hbox_widget;
	private TreeView tv_widget;
	private ScrolledWindow sw_widget;
	private Button btn_add_theme;
	private ToggleButton btn_show_widgets;
	private ToggleButton btn_show_themes;
	private ToggleButton btn_preview;
	private ToggleButton btn_list;
	private Gtk.Paned pane;
	private Label lblSaveThemeSeparator;
	private Label lblFilter;
	private Entry txtFilter;
	private TreeModelFilter filterThemes;
	
	//toolbar
	private Box toolbar;
	private Button btn_prev;
	private Button btn_next;
	private Button btn_start;
	private Button btn_start_terminal;
	private Button btn_stop;
	private Button btn_edit;
	private Button btn_edit_gui;
	private Button btn_open_dir;
	private Button btn_scan;
	private Button btn_generate_preview;
	private Button btn_kill_all;
	private Button btn_import_themes;
	private Button btn_settings;
	private Button btn_donate;
	private Button btn_about;
	
	//status
	private Box hbox_progressbar;
	private ProgressBar progressbar;
	private Label lbl_status;
	private Button btn_cancel_action;
	private ScrolledWindow sw_preview;
	//credits
	private Box hbox_credits;
	private Label lbl_credits;
	private Label lbl_source;
	private LinkButton lbtn_source;
	
	//window dimensions
	private bool is_running;
	private bool is_aborted;
	private ConkyRC current_rc;
	private uint timer_init;
	private Gee.ArrayList<ConkyRC> rclist_generate;

	public MainWindow(Gtk.Application app) {
		Object(application: app);
		title = AppName + " v" + AppVersion;
		modal = true;
		set_default_size(App.window_width, App.window_height);

		setup_drag_and_drop();
		
		string tt = "";

		//vbox_main
		var toolbar_view = new Adw.ToolbarView();
		var header_bar = new Adw.HeaderBar();
		header_bar.show_title = true;
		toolbar_view.add_top_bar(header_bar);

		vbox_main = new Box (Orientation.VERTICAL, 6);
		toolbar_view.set_content(vbox_main);
		set_content(toolbar_view);
		
		//toolbar
		init_toolbar();

		//hbox_widget
		hbox_widget = new Box (Orientation.HORIZONTAL, 6);
		hbox_widget.margin_start = 3;
		hbox_widget.margin_end = 3;
		vbox_main.append(hbox_widget);

		//lbl_type
		Label lbl_type = new Label (_("Browse:"));
		hbox_widget.append(lbl_type);
		
		//btn_show_widgets
		btn_show_widgets = new ToggleButton.with_label(_("Widgets"));
		hbox_widget.append(btn_show_widgets);
		
		//btn_show_themes
		btn_show_themes = new ToggleButton.with_label(_("Themes"));
		hbox_widget.append(btn_show_themes);
		
		btn_show_widgets.toggled.connect(()=>{
			if (btn_show_widgets.active){
				btn_show_themes.active = false;
				btn_add_theme.visible = false;
				btn_generate_preview.visible = true;
				
				lblSaveThemeSeparator.visible = btn_add_theme.visible;
				txtFilter.text = "";
				reload_themes();
			}
		});
		
		btn_show_themes.toggled.connect(()=>{
			if (btn_show_themes.active){
				btn_show_widgets.active = false;
				btn_add_theme.visible = true;
				btn_generate_preview.visible = false;
				
				lblSaveThemeSeparator.visible = btn_add_theme.visible;
				txtFilter.text = "";
				reload_themes();
			}
		});

		//separator
		hbox_widget.append(new Label(" | "));
		
		//add theme button
		btn_add_theme = new Button.with_label(_("Save Theme"));
		btn_add_theme.set_size_request(10,-1);
		btn_add_theme.set_tooltip_text(_("Save running widgets and current desktop wallpaper as new theme"));
		hbox_widget.append(btn_add_theme);
		
		btn_add_theme.clicked.connect(btn_add_theme_clicked);
		
		//separator
		lblSaveThemeSeparator = new Label(" | ");
		hbox_widget.append(lblSaveThemeSeparator);
		
		//filter
		lblFilter = new Label(_("Filter"));
		hbox_widget.append(lblFilter);
		
		txtFilter = new Entry();
		hbox_widget.append(txtFilter);
		txtFilter.changed.connect(()=>{ 
			filterThemes.refilter(); 
			show_preview(selected_item()); 
		});
		
		tt = _("Enter name or path to filter.\nEnter '0' to list running widgets");
		lblFilter.set_tooltip_text(tt);
		txtFilter.set_tooltip_text(tt);
		
		//lbl_expand
		Label lbl_expand = new Label ("");
		lbl_expand.hexpand = true;
		hbox_widget.append(lbl_expand);
		
		//btn_preview
		btn_preview = new ToggleButton.with_label(_("Preview"));
		btn_preview.active = App.show_preview;
		btn_preview.set_tooltip_text(_("Toggle Preview"));
		hbox_widget.append(btn_preview);

		//btn_list
		btn_list = new ToggleButton.with_label(_("List"));
		btn_list.active = App.show_list;
		btn_list.set_tooltip_text(_("Toggle List"));
		hbox_widget.append(btn_list);

		btn_preview.toggled.connect(btn_preview_toggled);
		btn_list.toggled.connect(btn_list_toggled);
		
		//status
        vbox_status = new Box (Orientation.VERTICAL, 3);
        vbox_status.set_margin_top(3);
		vbox_status.set_margin_bottom(3);
		vbox_status.set_margin_start(3);
		vbox_status.set_margin_end(3);
		vbox_main.append(vbox_status);

		lbl_status = new Label ("");
		lbl_status.halign = Align.START;
		lbl_status.max_width_chars = 100;
		lbl_status.ellipsize = Pango.EllipsizeMode.END;
		vbox_status.append(lbl_status);
		
		//progressbar
        hbox_progressbar = new Box (Orientation.HORIZONTAL, 6);
		vbox_status.append(hbox_progressbar);

		progressbar = new ProgressBar();
		progressbar.set_size_request(-1,20);
		hbox_progressbar.append(progressbar);

		btn_cancel_action = new Gtk.Button.with_label (" " + _("Stop") + " ");
		btn_cancel_action.set_size_request(50,-1);
		btn_cancel_action.set_tooltip_text(_("Stop"));
		hbox_progressbar.append(btn_cancel_action);
		
		pane = new Gtk.Paned (Gtk.Orientation.VERTICAL);
		pane.position = App.pane_position;
		vbox_main.append(pane);
		
		pane.notify["position"].connect (() => {
			App.pane_position = pane.position;
		});

		//credits
        hbox_credits = new Box (Orientation.HORIZONTAL, 3);
        //hbox_credits.set_margin_top(3);
		hbox_credits.set_margin_bottom(3);
		hbox_credits.set_margin_start(3);
		hbox_credits.set_margin_end(3);
		vbox_main.append(hbox_credits);

		lbl_source = new Label (_("Source") + ":");
		lbl_source.halign = Align.START;
		lbl_source.max_width_chars = 100;
		lbl_source.ellipsize = Pango.EllipsizeMode.END;
		hbox_credits.append(lbl_source);
		
		lbtn_source = new LinkButton("");
		lbtn_source.halign = Align.START;
		hbox_credits.append(lbtn_source);
		
		lbl_credits = new Label (_("Credits"));
		lbl_credits.halign = Align.START;
		lbl_credits.max_width_chars = 100;
		lbl_credits.ellipsize = Pango.EllipsizeMode.END;
		//hbox_credits.append(lbl_credits);
		
		//list_view
		init_list_view();
		
		//preview_area
		init_preview_area();

		//keyboard_shortcuts
		init_keyboard_shortcuts();

		timer_init = Timeout.add(100, init_delayed);
	}
	
	private void init_toolbar(){
        //toolbar
		toolbar = new Box(Orientation.HORIZONTAL, 6);
		toolbar.add_css_class("toolbar");
		vbox_main.append(toolbar);

		//btn_prev
		btn_prev = toolbar_button(_("Previous"), "go-previous-symbolic");
		btn_prev.set_tooltip_text (_("Previous Widget"));
//        toolbar.append(btn_prev);

        btn_prev.clicked.connect(btn_prev_clicked);

		//btn_next
		btn_next = toolbar_button(_("Next"), "go-next-symbolic");
		btn_next.set_tooltip_text (_("Next Widget"));
//        toolbar.append(btn_next);

        btn_next.clicked.connect(btn_next_clicked);

		//btn_start terminal
		btn_start_terminal = toolbar_button(_("Terminal Start"), "utilities-terminal-symbolic");
		btn_start_terminal.set_tooltip_text (_("Start/Restart Widget in Terminal"));
        toolbar.append(btn_start_terminal);

        btn_start_terminal.clicked.connect(btn_start_terminal_clicked);

		//btn_start
		btn_start = toolbar_button(_("Start"), "media-playback-start-symbolic");
		btn_start.set_tooltip_text (_("Start/Restart Widget"));
        toolbar.append(btn_start);

        btn_start.clicked.connect(btn_start_clicked);

		//btn_stop
		btn_stop = toolbar_button(_("Stop"), "media-playback-stop-symbolic");
		btn_stop.set_tooltip_text (_("Stop Widget"));
        toolbar.append(btn_stop);

        btn_stop.clicked.connect(btn_stop_clicked);
        
        //separator1
		var separator1 = new Gtk.Separator(Orientation.VERTICAL);
		toolbar.append(separator1);
		
		//btn_edit_gui
		btn_edit_gui = toolbar_button(_("Edit"), "document-properties-symbolic");
		btn_edit_gui.set_tooltip_text (_("Edit Widget"));
        toolbar.append(btn_edit_gui);

        btn_edit_gui.clicked.connect(btn_edit_gui_clicked);
        
		//btn_edit
		btn_edit = toolbar_button(_("Manual Edit"), "document-edit-symbolic");
		btn_edit.set_tooltip_text (_("Edit file manually in a text editor"));
        toolbar.append(btn_edit);

        btn_edit.clicked.connect(btn_edit_clicked);

		//btn_open_dir
		btn_open_dir = toolbar_button(_("Open Folder"), "folder-open-symbolic");
		btn_open_dir.set_tooltip_text (_("Open Theme Folder"));
        toolbar.append(btn_open_dir);

        btn_open_dir.clicked.connect(btn_open_dir_clicked);

        //separator1
		var separator2 = new Gtk.Separator(Orientation.VERTICAL);
		toolbar.append(separator2);

		//btn_scan
		btn_scan = toolbar_button(_("Refresh"), "view-refresh-symbolic");
		btn_scan.set_tooltip_text (_("Search for new themes"));
        toolbar.append(btn_scan);

        btn_scan.clicked.connect(btn_scan_clicked);
        
		//btn_generate_preview
		btn_generate_preview = toolbar_button(_("Generate Preview"), "image-x-generic-symbolic");
		btn_generate_preview.set_tooltip_text (_("Generate preview images"));
        toolbar.append(btn_generate_preview);
		
        btn_generate_preview.clicked.connect(btn_generate_preview_clicked);

		//btn_kill_all
		btn_kill_all = toolbar_button(_("Stop All Widgets"), "process-stop-symbolic");
		btn_kill_all.set_tooltip_text (_("Stop all running widgets"));
        toolbar.append(btn_kill_all);

        btn_kill_all.clicked.connect(btn_kill_all_clicked);

		//btn_import_themes
		btn_import_themes = toolbar_button(_("Import"), "document-open-symbolic");
		btn_import_themes.set_tooltip_text (_("Import Theme Pack (*.cmtp.7z) or various archive type"));
        toolbar.append(btn_import_themes);

        btn_import_themes.clicked.connect(btn_import_themes_clicked);
        
        //separator
		var separator = new Label("");
		separator.hexpand = true;
		toolbar.append(separator);
		
		//btn_settings
		btn_settings = toolbar_button(_("Settings"), "emblem-system-symbolic");
		btn_settings.set_tooltip_text (_("Application Settings"));
        toolbar.append(btn_settings);

	        btn_settings.clicked.connect(btn_settings_clicked);

	        //btn_donate
			btn_donate = toolbar_button_with_fallback_icon(_("Funding"), "donate-symbolic", "donate.svg");
			btn_donate.set_tooltip_text (_("Funding Support"));
	        toolbar.append(btn_donate);

        btn_donate.clicked.connect(() => { show_donation_window(false); });
        
        //btn_about
		btn_about = toolbar_button(_("About"), "help-about-symbolic");
		btn_about.set_tooltip_text (_("About"));
        toolbar.append(btn_about);

        btn_about.clicked.connect(btn_about_clicked);
	}

	private Button toolbar_button(string label, string icon_name){
		var button = new Button.with_label(label);
		button.set_icon_name(icon_name);
		return button;
	}

	private Button toolbar_button_with_fallback_icon(string label, string icon_name, string fallback_icon_file_name){
		var button = new Button();
		var image = get_shared_icon(icon_name, fallback_icon_file_name, 20);

		if (image != null){
			button.set_child(image);
		}
		else{
			button.label = label;
		}

		return button;
	}
	
	private void init_list_view(){
		//list view
		tv_widget = new TreeView();
		tv_widget.get_selection().mode = SelectionMode.SINGLE;
		tv_widget.headers_visible = false;
		
		sw_widget = new ScrolledWindow();
		sw_widget.set_child(tv_widget);
		sw_widget.hexpand = true;
		sw_widget.vexpand = true;
		pane.set_start_child(sw_widget);
		pane.resize_start_child = true;
		pane.shrink_start_child = true;

		TreeViewColumn col_widget = new TreeViewColumn();
		col_widget.title = " " + _("Enable") + " ";
		tv_widget.append_column(col_widget);
		
		CellRendererToggle cell_widget_enable = new CellRendererToggle ();
		cell_widget_enable.activatable = true;
		col_widget.pack_start (cell_widget_enable, false);
		
		col_widget.set_cell_data_func (cell_widget_enable, (cell_layout, cell, model, iter)=>{
			bool val;
			model.get (iter, 0, out val, -1);
			(cell as Gtk.CellRendererToggle).active = val;
		});
		
		cell_widget_enable.toggled.connect (cell_widget_enable_toggled);

		CellRendererText cell_widget_name = new CellRendererText ();
		col_widget.pack_start (cell_widget_name, false);
		
		col_widget.set_cell_data_func (cell_widget_name, (cell_layout, cell, model, iter)=>{
			ConkyRC rc;
			model.get (iter, 1, out rc, -1);
			(cell as Gtk.CellRendererText).text = rc.name;
		});
		
		TreeSelection sel = tv_widget.get_selection();
		sel.changed.connect(()=>{
			show_preview(selected_item());
		});
	}
	
	private void init_preview_area(){
		sw_preview = new ScrolledWindow();
		sw_preview.hexpand = true;
		sw_preview.vexpand = true;
		pane.set_end_child(sw_preview);
		pane.resize_end_child = true;
		pane.shrink_end_child = true;
		
		string tt = _("Use the keyboard arrow keys to browse.\nPress ENTER to start and stop.");
		sw_preview.set_tooltip_text(tt);

		img_preview = new Image();
		sw_preview.set_child(img_preview);
	}

	private void setup_drag_and_drop(){
		var drop_target = new Gtk.DropTarget(typeof(Gdk.FileList), Gdk.DragAction.COPY);
		drop_target.drop.connect((value, x, y) => {
			var file_list = (Gdk.FileList) value.get_boxed();
			if (file_list == null) { return false; }

			SList<string> files = new SList<string>();
			foreach(File file in file_list.get_files()){
				string path = file.get_path();
				if (path == null) { continue; }
				if ( path.has_suffix(".7z") || path.has_suffix(".bz2") || path.has_suffix(".gz") 
					|| path.has_suffix(".xz") || path.has_suffix(".tar") || path.has_suffix(".zip") ){
					files.append(path);
				}
			}

			if (files.length() == 0) { return false; }
			install_theme_packs(files);
			return true;
		});
		((Gtk.Widget) this).add_controller(drop_target);
	}
	
	private void init_keyboard_shortcuts(){
		var key_controller = new Gtk.EventControllerKey();
		key_controller.key_pressed.connect((keyval, keycode, state) => {

			if (!toolbar.sensitive) { return false; }

			if ((keyval == 65361)||(keyval == 65362)) {
				btn_prev_clicked();
				return false;
			}
			else if ((keyval == 65363)||(keyval == 65364)){
				btn_next_clicked();
				return false;
			}
			else if (keyval == 65293) {
				if (selected_item().enabled){
					btn_stop_clicked();
				}
				else{
					btn_start_clicked();
				}
				return true;
			}

			return false;
		});
		((Gtk.Widget) this).add_controller(key_controller);
	}
	
	private bool init_delayed(){
		Source.remove(timer_init);
		
		//call handlers
		btn_preview_toggled();
		btn_list_toggled();
		btn_show_widgets.active = true;

		btn_scan_clicked();
		
		return true;
	}
	
	private void reload_themes(){
		
		txtFilter.text = "";
		
		double vpos = sw_widget.vadjustment.value;
		
		tv_widget_refresh();
		show_preview(selected_item());
		
		if (btn_preview.active){
			sw_preview.visible = true;
		}
		
		if (btn_list.active){
			sw_widget.visible = true;
		}

		sw_widget.vadjustment.value = vpos;
	}

	//actions
	
	private void btn_preview_toggled(){
		App.show_preview = btn_preview.active;
		sw_preview.visible = App.show_preview;
		if ((!btn_list.active)&&(!btn_preview.active)){
			btn_list.active = true;
		}
	}

	private void btn_list_toggled(){
		App.show_list = btn_list.active;
		sw_widget.visible = App.show_list;
		if ((!btn_list.active)&&(!btn_preview.active)){
			btn_preview.active = true;
		}
	}

	private void btn_add_theme_clicked(){
		App.refresh_conkyrc_status();
		
		var dialog = new EditThemeWindow(null);
		dialog.set_transient_for (this);
		dialog.present();
		gtk_dialog_run(dialog);
		dialog.destroy();
		
		reload_themes();
	}
	
	private void btn_prev_clicked(){
		TreeModel model;
		TreeSelection selection = tv_widget.get_selection();
		TreeIter iter;
		
		if (selection.count_selected_rows() > 0){
			selection.get_selected(out model, out iter);

			if (model.iter_previous(ref iter)){
				selection.select_iter(iter);
			}
		}	

		show_preview(selected_item());
	}
	
	private void btn_next_clicked(){
		TreeModel model;
		TreeSelection selection = tv_widget.get_selection();
		TreeIter iter;

		if (selection.count_selected_rows() > 0){
			selection.get_selected(out model, out iter);

			if (model.iter_next(ref iter)){
				selection.select_iter(iter);
			}
		}	

		show_preview(selected_item());
	}

	private void btn_start_terminal_clicked(){
		TreeModel model;
		TreeStore store = (TreeStore) filterThemes.child_model;
		TreeSelection selection = tv_widget.get_selection();
		TreeIter iter, child_iter;
		ConkyConfigItem item;

		//check if selected
		if (selection.count_selected_rows() == 0){ return; }

		//get item
		selection.get_selected(out model, out iter);
		model.get(iter,1,out item,-1);

		//show busy icon
		gtk_set_busy(true, this);
		gtk_do_events();

		//start item
		item.terminal_start();
		show_preview(item);

		//hide busy icon
		gtk_set_busy(false, this);

		//uncheck other items
		if (item is ConkyTheme){
			TreeIter iter2;
			bool iterExists = model.get_iter_first (out iter2);
			while (iterExists){
				if (iter2 != iter){
					//uncheck
					filterThemes.convert_iter_to_child_iter(out child_iter, iter2);
					store.set(child_iter, 0, false);
				}
				iterExists = model.iter_next (ref iter2);
			}
		}

		//check item
		filterThemes.convert_iter_to_child_iter(out child_iter, iter);
		store.set(child_iter, 0, true, -1);
	}

	private void btn_start_clicked(){
		TreeModel model;
		TreeStore store = (TreeStore) filterThemes.child_model;
		TreeSelection selection = tv_widget.get_selection();
		TreeIter iter, child_iter;
		ConkyConfigItem item;

		//check if selected
		if (selection.count_selected_rows() == 0){ return; }

		//get item
		selection.get_selected(out model, out iter);
		model.get(iter,1,out item,-1);

		//show busy icon
		gtk_set_busy(true, this);
		gtk_do_events();
		
		//start item
		item.start();
		show_preview(item);

		//hide busy icon
		gtk_set_busy(false, this);
		
		//uncheck other items
		if (item is ConkyTheme){
			TreeIter iter2;
			bool iterExists = model.get_iter_first (out iter2);
			while (iterExists){
				if (iter2 != iter){
					//uncheck
					filterThemes.convert_iter_to_child_iter(out child_iter, iter2);
					store.set(child_iter, 0, false);
				}
				iterExists = model.iter_next (ref iter2);
			}
		}

		//check item
		filterThemes.convert_iter_to_child_iter(out child_iter, iter);
		store.set(child_iter, 0, true, -1);
	}
	
	private void btn_stop_clicked(){
		TreeModel model = (TreeModel) filterThemes;
		TreeStore store = (TreeStore) filterThemes.child_model;
		TreeSelection selection = tv_widget.get_selection();
		TreeIter iter, child_iter;
		ConkyConfigItem item;
		
		//check if selected
		if (selection.count_selected_rows() == 0){ return; }
		
		//get item
		selection.get_selected(out model, out iter);
		model.get(iter,1,out item,-1);

		//show busy icon
		gtk_set_busy(true, this);
		gtk_do_events();
		
		//stop
		item.stop();
		show_preview(item);

		//hide busy icon
		gtk_set_busy(false, this);
		
		//uncheck item
		filterThemes.convert_iter_to_child_iter(out child_iter, iter);
		store.set(child_iter, 0, false, -1);
	}
	
	private void btn_edit_gui_clicked(){
		ConkyConfigItem item = selected_item();
		
		if (item is ConkyRC){
			var dialog = new EditWidgetWindow((ConkyRC) item);
			dialog.set_transient_for(this);
			dialog.present();
			gtk_dialog_run(dialog);
			dialog.destroy();
		}
		else{
			App.refresh_conkyrc_status();
			
			var dialog = new EditThemeWindow((ConkyTheme)selected_item());
			dialog.set_transient_for (this);
			dialog.present();
			gtk_dialog_run(dialog);
			dialog.destroy();
		}
	}
	
	private void btn_edit_clicked(){
		ConkyConfigItem item = selected_item();
		if (item != null) { xdg_open(item.path); };
	}

	private void btn_open_dir_clicked(){
		ConkyConfigItem item = selected_item();
		if (item != null) { exo_open_folder(item.dir); };
	}
	
	private void btn_scan_clicked(){
		scan_themes();
	}

	private void btn_generate_preview_clicked(){
		//get options
		var dialog = new GeneratePreviewWindow();
		dialog.set_transient_for (this);
		dialog.present();
		dialog.optGenerateCurrent.sensitive = (selected_item() != null);
		dialog.optGenerateMissing.active = (selected_item() == null);
		
		int response = gtk_dialog_run(dialog);
		string action = dialog.action;
		dialog.destroy();
		
		//clear list
		rclist_generate = new Gee.ArrayList<ConkyRC>();
		
		//make list
		if (response == Gtk.ResponseType.OK){
			switch(action){
				case "current":
					rclist_generate.add((ConkyRC)selected_item());
					break;
				case "missing":
					foreach(ConkyRC rc in App.conkyrc_list){
						//check if image file is a "default" image
						string[] ext_list = {".png",".jpg",".jpeg"};
						foreach(string ext in ext_list){
							string image_name = "preview" + ext;
							if (rc.image_path.has_suffix(image_name)){ 
								rclist_generate.add(rc);
								continue;
							}
						}
						
						//check if image file is missing
						if (!file_exists(rc.image_path)){
							rclist_generate.add(rc);
						}
					}
					break;
				case "all":
					foreach(ConkyRC rc in App.conkyrc_list){
						rclist_generate.add(rc);
					}
					break;
			}
		}
		else{ 
			return; //cancel
		}

		progress_begin(_("Generating Previews") + "...");
		
		//change view
		bool show_preview = btn_preview.active;
		bool show_list = btn_list.active;
		btn_preview.active = true;
		btn_list.active = false;
		
		is_aborted = false;

		btn_cancel_action.clicked.connect(btn_cancel_action_generate_preview);
		
		try {
			is_running = true;
			Thread.create<void> (btn_generate_preview_clicked_thread, true);
		} catch (ThreadError e) {
			is_running = false;
			log_error (e.message);
		}

		while(is_running){
			Thread.usleep ((ulong) 200000);
			gtk_do_events();
		}
				
		btn_cancel_action.clicked.disconnect(btn_cancel_action_generate_preview);
		
		progress_hide();
		
		//restore selected view
		btn_preview.active = show_preview;
		btn_list.active = show_list;
		
		//reload_themes();
	}
	
	private void btn_generate_preview_clicked_thread(){
		gtk_set_busy(true,this);
		
		generate_previews();
		is_running = false;
		
		gtk_set_busy(false,this);
	}
	
	private void generate_previews(){
		
		//save running widgets
		var running_list = new Gee.ArrayList<string>();
		foreach(ConkyRC rc in App.conkyrc_list){
			if (rc.enabled){
				running_list.add(rc.path);
			}
		}
		
		//kill running widgets
		App.kill_all_conky();
		
		int count_total = rclist_generate.size;
		int count = 0;
		
		foreach(ConkyRC rc in rclist_generate){
			
			if (is_aborted) { break; }
			
			current_rc = rc;
			rc.generate_preview();
			current_rc = null;

			count++;
			progressbar.fraction = count / (count_total * 1.0);

			show_preview(rc);
			
			lbl_status.label = _("Generating Previews") + " [%d OF %d]\n%s".printf(count, count_total, rc.name);
			gtk_do_events();
		}
		
		//start widgets that were running
		foreach(ConkyRC rc in App.conkyrc_list){
			if (running_list.contains(rc.path)){
				rc.start();
			}
		}
		
		//show previously selected widget
		show_preview(selected_item());
	}
	
	private void btn_cancel_action_scan(){
		App.load_themes_and_widgets_cancel();
	}
	
	private void btn_cancel_action_generate_preview(){
		is_aborted = true;
		App.kill_all_conky();
	}
	
	private void btn_kill_all_clicked(){
		App.kill_all_conky();
		
		TreeModel model = filterThemes;
		TreeStore store = (TreeStore) filterThemes.child_model;
		TreeIter iter;

		bool iterExists = model.get_iter_first (out iter);
		while (iterExists){
			store.set (iter, 0, false, -1);
			iterExists = model.iter_next (ref iter);
		}
	}

	private void btn_import_themes_clicked(){
		var dialog = new FileDialog();
		dialog.title = _("Import") + " (cmtp.7z; 7z; gz; bz2; xz; tar; zip; etc.)";
		dialog.modal = true;

		Gtk.FileFilter filter = new Gtk.FileFilter ();
		filter.add_pattern ("*.cmtp.7z");
		filter.add_pattern ("*.7z");
		filter.add_pattern ("*.tar.7z");
		filter.add_pattern ("*.gz");
		filter.add_pattern ("*.tar.gz");
		filter.add_pattern ("*.bz2");
		filter.add_pattern ("*.tar.bz2");
		filter.add_pattern ("*.xz");
		filter.add_pattern ("*.tar.xz");
		filter.add_pattern ("*.tar");
		filter.add_pattern ("*.zip");
        filter.set_filter_name("Conky Manager Theme or various compressed archive");

		var filters = new GLib.ListStore(typeof(Gtk.FileFilter));
		filters.append(filter);
		dialog.filters = filters;
		dialog.default_filter = filter;

		dialog.open_multiple.begin(this, null, (obj, res) => {
			try{
				ListModel? model = dialog.open_multiple.end(res);
				if (model == null) { return; }

				var files = files_from_list_model(model);
				if (files.length() == 0) { return; }

				install_theme_packs(files);
			}
			catch(Error e){
				log_debug(e.message);
			}
		});
	}
	
	private void install_theme_packs(SList<string> files){
		gtk_set_busy(true, this);
		gtk_do_events();
		
		bool ok = true;
		foreach (string file in files){
			if (file.has_suffix(".tar.7z") || file.has_suffix(".tar.bz2") || file.has_suffix(".tar.gz") 
                || file.has_suffix(".tar.xz") || file.has_suffix(".tar"))
				ok = ok && App.install_theme_pack(file, true);
            else
				ok = ok && App.install_theme_pack(file);
		}
		
		scan_themes();

		gtk_set_busy(false, this);
		
		if (ok){
			gtk_messagebox(_("Themes Imported"), _("Themes imported successfully"),this);
		}
		else{
			gtk_messagebox(_("Error"), _("Failed to import themes"),this);
		}
	}

	private SList<string> files_from_list_model(ListModel model){
		SList<string> files = new SList<string>();
		for (uint i = 0; i < model.get_n_items(); i++){
			File? file = model.get_item(i) as File;
			if (file == null) { continue; }
			string? path = file.get_path();
			if (path != null){
				files.append(path);
			}
		}
		return files;
	}
	
	private void btn_settings_clicked(){
		var dialog = new SettingsWindow();
		dialog.set_transient_for(this);
		dialog.present();
		gtk_dialog_run(dialog);
		dialog.destroy();
	}

	public void show_donation_window(bool on_exit){
		var dialog = new DonationWindow();
		dialog.set_transient_for(this);
		dialog.present();
		gtk_dialog_run(dialog);
		dialog.destroy();
	}

	private void btn_about_clicked(){
		var dialog = new AboutWindow();
		dialog.set_transient_for (this);

		dialog.authors = {
			"Tony George:teejeetech@gmail.com",
			"Scott Caudle:zcotcaudle@gmail.com"
		};

		dialog.translators = {
			"yeji0407 (Korean):github.com/yeji0407",
			"freddii (German):github.com/freddii",
			"fehlix (French):github.com/fehlix",
			"tioguda (Portuguese - Brazil):github.com/tioguda",
			"Vistaus (Dutch):github.com/Vistaus",
			"gogo (Croatian):launchpad.net/~trebelnik-stefina",
			"Radek Otáhal (Czech):radek.otahal@email.cz"
		}; 
		
		dialog.third_party = {
			"Conky Manager is powered by the following tools and components. Please visit the links for more information.",
			"Conky by Brenden Matthews:http://conky.sourceforge.net/",
			"ImageMagick by ImageMagick Studio LLC:http://imagemagick.org/",
			"7-Zip by Igor Pavlov:http://www.7-zip.org/",
			"Themes by various authors from DeviantArt.com:http://www.deviantart.com/browse/all/customization/skins/?q=conky"
		}; 
		
		dialog.documenters = null; 
		dialog.artists = {
			"Morten Kjeldgaard"
		}; 
		
		dialog.donations = {
			"Adam Simmons",
			"Andre Strobach",
			"Dan Raymond",
			"Edwin Pallens",
			"Flaviu Dan",
			"Gus Chavez",
			"Jan Sandberg",
			"Jesse Avalos",
			"John Cruz",
			"Nicola Jelmorini",
			"Radek Otahal",
			"Raymond Shaffer",
			"Steven Dudek",
			"Steven Klausmeier",
			"Umut Baris Demir",
			"Will Hartley",
			"William Keller"
		};
		
		dialog.program_name = AppName;
		dialog.comments = _("Utility for managing Conky configuration files");
		dialog.copyright = "Copyright © 2014 Tony George (%s)".printf(AppAuthorEmail);
		dialog.copyright2 = "Copyright © 2018 Scott Caudle (%s)".printf(AppAuthorEmail2);
		dialog.copyright3 = "Copyright © 2026 lerosua with codex gpt-5.5";
		dialog.version = AppVersion;
		dialog.logo = get_app_icon(128);

		dialog.license = "This program is free for personal and commercial use and comes with absolutely no warranty. You use this program entirely at your own risk. The author will not be liable for any damages arising from the use of this program.";
		dialog.website = "http://teejeetech.in";
		dialog.website_label = "http://teejeetech.blogspot.in";
		dialog.website2 = "https://github.com/zcot/conky-manager2";
		dialog.website_label2 = "https://github.com/zcot/conky-manager2";
		dialog.website3 = "https://github.com/lerosua/conky-manager3";
		dialog.website_label3 = "https://github.com/lerosua/conky-manager3";

		dialog.initialize();
		dialog.present();
	}
	
	private void show_preview(ConkyConfigItem? item){
		img_preview.clear();
		
		if (item == null){
			img_preview.clear();
			return;
		}
		
		int screen_width = get_width();
		int screen_height = get_height();

		if ((item.image_path.length > 0) && file_exists(item.image_path)){
			try{
				Gdk.Pixbuf px = new Gdk.Pixbuf.from_file(item.image_path);

				//scale down the image if it is very large
				if ((px.width > (screen_width * 1.5)) || (px.height > (screen_height * 1.5))){
					//scale down 50%
					int scaled_width = px.width / 2;
					int scaled_height = px.height / 2;
					px = new Gdk.Pixbuf.from_file_at_scale(item.image_path,scaled_width,scaled_height,true);
					img_preview.set_from_pixbuf(px);
				}
				else{
					img_preview.set_from_pixbuf(px);
				}
			}
			catch(Error e){
				log_error (e.message);
			}
		}
		else{
			img_preview.clear();
		}
		
		if (item.url.length > 0){
			lbtn_source.uri = item.url;
			lbtn_source.label = item.url;
		}
		else{
			lbtn_source.uri = "";
			lbtn_source.label = _("N/A");
		}
		
		if (item.credits.length > 0){
			//lbl_credits.visible = true;
		}
		else{
			//lbl_credits.visible = false;
		}
	}

	private void scan_themes(){
		progress_begin(_("Searching directories..."));

		btn_cancel_action.clicked.connect(btn_cancel_action_scan);
		
		try {
			is_running = true;
			Thread.create<void> (scan_themes_thread, true);
		} catch (ThreadError e) {
			is_running = false;
			log_error (e.message);
		}

		while(is_running){
			Thread.usleep ((ulong) 200000);
			progressbar.pulse();
			gtk_do_events();
		}
		
		btn_cancel_action.clicked.disconnect(btn_cancel_action_scan);
		
		progress_hide();

		reload_themes();
	}
	
	private void scan_themes_thread(){
		App.load_themes_and_widgets();
		reload_themes();
		is_running = false;
	}

	private void progress_begin(string message = ""){
		toolbar.sensitive = false;
		hbox_widget.visible = false;

		vbox_status.visible = true;
		lbl_status.visible = true;
		hbox_progressbar.visible = true;
		progressbar.visible = true;
		btn_cancel_action.visible = true;

		progressbar.fraction = 0.0;
		lbl_status.label = message;
		
		hbox_credits.visible = false;
		
		//gtk_set_busy(true, this);
		gtk_do_events();
	}
	
	private void progress_hide(string message = ""){
		toolbar.sensitive = true;		
		hbox_widget.visible = true;		

		vbox_status.visible = false;
		lbl_status.visible = false;
		hbox_progressbar.visible = false;
		progressbar.visible = false;
		btn_cancel_action.visible = false;

		progressbar.fraction = 0.0;
		lbl_status.label = message;

		hbox_credits.visible = true;
		
		//gtk_set_busy(false, this);
		gtk_do_events();
	}
	
	private ConkyConfigItem? selected_item(){
		TreeSelection selection = tv_widget.get_selection();
		TreeModel model;
		TreeIter iter;
		ConkyConfigItem item;
			
		if (selection.count_selected_rows() > 0){
			selection.get_selected(out model, out iter);
			model.get(iter, 1, out item, -1);
			return item;
		}	
		else{
			return null;
		}
	}
	
	//list view handlers

	private void tv_widget_refresh(){
		TreeStore model = new TreeStore(2, typeof(bool), typeof(ConkyConfigItem));
		
		Gee.ArrayList<ConkyConfigItem> list = null;
		if (btn_show_widgets.active){
			list = App.conkyrc_list;
		}
		else{
			list = App.conkytheme_list;
		}
		
		foreach(ConkyConfigItem item in list){
			if ((btn_show_widgets.active) && (App.show_active)){
				if (!item.enabled) { 
					continue; 
				}
			}
			
			TreeIter iter;
			model.append(out iter, null);
			model.set(iter, 0, item.enabled);
			model.set(iter, 1, item);
		}
		
		filterThemes = new TreeModelFilter (model, null);
		filterThemes.set_visible_func(filterThemes_filter);
		tv_widget.set_model (filterThemes);
		tv_widget.columns_autosize();
	}

	private bool filterThemes_filter (Gtk.TreeModel model, Gtk.TreeIter iter){
		if ((txtFilter.text == null)||(txtFilter.text.strip().length == 0)){
			return true;
		}
		
		ConkyConfigItem item;
		model.get (iter, 1, out item, -1);
		
		switch (txtFilter.text.strip().down()){
			case "0":
				return item.enabled;
		}
		
		try{
			Regex regexName = new Regex (txtFilter.text, RegexCompileFlags.CASELESS);
			MatchInfo match;

			if (regexName.match (item.name, 0, out match)) {
				return true;
			}
			else {
				return false;
			}
		}
		catch (Error e) {
			return false;
		}
	}

	private void cell_widget_enable_toggled (string path){
		TreeModel model = filterThemes;
		TreeIter iter;
		bool enabled;
		
		//select clicked row if unselected
		TreeSelection selection = tv_widget.get_selection();
		selection.select_path(new TreePath.from_string(path));
		
		//get state
		model.get_iter_from_string (out iter, path);
		model.get (iter, 0, out enabled, -1);
		
		//toggle
		enabled = !enabled;
		
		if (enabled){
			btn_start_clicked();
		}
		else{
			btn_stop_clicked();
		}
	}
}
