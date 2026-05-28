/*
 * GeneratePreviewWindow.vala
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

public class GeneratePreviewWindow : Dialog {
	private Button btn_ok;
	private Button btn_cancel;
	public string action = "";
	public CheckButton optGenerateCurrent;
	public CheckButton optGenerateMissing;
	public CheckButton optGenerateAll;
	private Switch switch_capture_bg;
	private Switch switch_png;
	
	public GeneratePreviewWindow() {
		title = _("Generate Preview");
		gtk_use_adwaita_titlebar(this);
		set_destroy_with_parent (true);
		set_modal (true);
        set_default_size (350, 300);	
		
	    Box vbox_main = get_content_area();
		vbox_main.set_margin_top(6);
		vbox_main.set_margin_bottom(6);
		vbox_main.set_margin_start(6);
		vbox_main.set_margin_end(6);
		vbox_main.spacing = 6;
		
		Label lbl_header = new Gtk.Label("<b>" + _("Generate preview images for") + ":</b>");
		lbl_header.set_use_markup(true);
		lbl_header.xalign = (float) 0.0;
		lbl_header.margin_bottom = 6;
		vbox_main.append(lbl_header);
		
		optGenerateCurrent = new CheckButton.with_label (_("Selected Widget"));
		vbox_main.append(optGenerateCurrent);
		
		optGenerateMissing = new CheckButton.with_label (_("All Widgets with Missing Previews"));
		optGenerateMissing.set_group(optGenerateCurrent);
		vbox_main.append(optGenerateMissing);

		optGenerateAll = new CheckButton.with_label (_("All Widgets (Overwrite Existing Image)"));
		optGenerateAll.set_group(optGenerateCurrent);
		vbox_main.append(optGenerateAll);

		Label lbl_header2 = new Gtk.Label("<b>" + _("Options") + ":</b>");
		lbl_header2.set_use_markup(true);
		lbl_header2.xalign = (float) 0.0;
		lbl_header2.margin_bottom = 6;
		lbl_header2.margin_top = 12;
		vbox_main.append(lbl_header2);
		
		//transparent background
		Box hbox_capture_bg = new Box (Gtk.Orientation.HORIZONTAL, 6);
        vbox_main.append (hbox_capture_bg);
        
		Label lbl_capture_bg = new Gtk.Label(_("Transparent Preview Background") );
		lbl_capture_bg.hexpand = true;
		lbl_capture_bg.xalign = (float) 0.0;
		lbl_capture_bg.valign = Align.CENTER;
		lbl_capture_bg.set_tooltip_text(_("When enabled, PNG previews are generated with a transparent background. Desktop background capture is not used."));
		hbox_capture_bg.append(lbl_capture_bg);

        switch_capture_bg = new Gtk.Switch();
        switch_capture_bg.halign = Align.END;
        switch_capture_bg.valign = Align.CENTER;
        switch_capture_bg.active =  App.capture_background;
        hbox_capture_bg.append(switch_capture_bg);
		
		switch_capture_bg.notify["active"].connect(()=>{
			App.capture_background = switch_capture_bg.active;
		});
		
		
		//png images
		Box hbox_png = new Box (Gtk.Orientation.HORIZONTAL, 6);
        vbox_main.append (hbox_png);
        
		Label lbl_png = new Gtk.Label(_("High quality images (PNG)") );
		lbl_png.hexpand = true;
		lbl_png.xalign = (float) 0.0;
		lbl_png.valign = Align.CENTER;
		lbl_png.set_tooltip_text(_("Generate preview images in PNG format instead of JPEG"));
		hbox_png.append(lbl_png);

        switch_png = new Gtk.Switch();
        switch_png.halign = Align.END;
        switch_png.valign = Align.CENTER;
        switch_png.active =  App.generate_png;
        hbox_png.append(switch_png);
		
		switch_png.notify["active"].connect(()=>{
			App.generate_png = switch_png.active;
		});
		
		//hbox_commands --------------------------------------------------
		
		//btn_ok
		btn_ok = new Button.with_label("  " + _("OK"));
		
        btn_ok.clicked.connect(()=>{ 
			if (optGenerateCurrent.active){
				action = "current";
			}
			else if (optGenerateMissing.active){
				action = "missing";
			}
			else if (optGenerateAll.active){
				action = "all";
			}
			else {
				action = "";
			}
			
			this.response(Gtk.ResponseType.OK); 
			});
			
		add_action_widget(btn_ok, Gtk.ResponseType.OK);
		
		//btn_cancel
		btn_cancel = new Button.with_label("  " + _("Cancel"));
        btn_cancel.clicked.connect(()=>{ this.response(Gtk.ResponseType.CANCEL); });
		add_action_widget(btn_cancel, Gtk.ResponseType.CANCEL);
	}
}
