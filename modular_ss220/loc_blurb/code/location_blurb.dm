/obj/screen/text/blurb
	maptext_height = 64
	maptext_width = 512
	screen_loc = "LEFT+1,BOTTOM+2"
	/// Font size in pixels
	var/font_size = 11
	/// Font family
	var/font_family = "Fixedsys"
	/// Where text is aligned
	var/text_alignment = "left"
	/// Color of text in RGB
	var/text_color = COLOR_WHITE
	/// Color of text outline
	var/text_outline_color = COLOR_BLACK
	/// Width of text outline in pixels
	var/text_outline_width = 1
	/// Text that will be shown in blurb
	var/blurb_text = ""
	/// Number of chars from the `text` that will be displayed per interval. Defaults to 1
	var/chars_per_interval = 1
	/// The interval between chars rendering
	var/interval = 1 DECISECONDS
	/// Amount of time the blurb will be present on the screen. 0 means that blurb will dissappear immediately
	var/hold_for = 0
	/// Amount of time the blurbs appering (alpha changing from 0 to 255). 0 means blurb is fully opaque from the start
	var/appear_animation_duration = 0
	/// Amount of time the blurb takes to fade (alpha changing from 255 to 0). 0 means blurb is instantly removed from the screen after finished
	var/fade_animation_duration = 0


/obj/screen/text/blurb/proc/show_to(list/client/viewers)
	if(!blurb_text || !viewers)
		return

	if(islist(viewers))
		if(!length(viewers))
			return

	else
		viewers = list(viewers)

	for(var/client/viewer as anything in viewers)
		if(viewer)
			viewer.screen += src

	appear()
	print_text()

	if(hold_for)
		addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/screen/text/blurb, hide_from), viewers), hold_for)
	else
		hide_from(viewers)


/obj/screen/text/blurb/proc/get_text_style()
	PRIVATE_PROC(TRUE)

	return {"\
		font-family: [font_family], [initial(font_family)]; \
		-dm-text-outline: [text_outline_width] [text_outline_color]; \
		font-size: [font_size]px; \
		text-align: [text_alignment]; \
		color: [text_color];
	"}

/obj/screen/text/blurb/proc/hide_from(list/client/viewers)
	PRIVATE_PROC(TRUE)

	fade()
	addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/screen/text/blurb, remove_from_viewers), viewers), fade_animation_duration)

/obj/screen/text/blurb/proc/appear()
	PRIVATE_PROC(TRUE)

	animate(src, alpha = 255, time = appear_animation_duration)


/obj/screen/text/blurb/proc/fade()
	PRIVATE_PROC(TRUE)

	animate(src, alpha = 0, time = fade_animation_duration)


/obj/screen/text/blurb/proc/print_text()
	PRIVATE_PROC(TRUE)

	var/text_style = get_text_style()
	var/text_length = length_char(blurb_text)
	for(var/segment_start = 1, segment_start <= text_length, segment_start += chars_per_interval)
		var/segment_end = min(text_length + 1, segment_start + chars_per_interval)
		maptext += get_formatted_text_segment(text_style, segment_start, segment_end)
		sleep(interval)

/obj/screen/text/blurb/proc/get_formatted_text_segment(style, segment_start, segment_end)
	return "<span style=\"[style]\">[copytext_char(blurb_text, segment_start, segment_end)]</span>"

/obj/screen/text/blurb/proc/remove_from_viewers(list/client/viewers)
	PRIVATE_PROC(TRUE)

	for(var/client/viewer as anything in viewers)
		if(viewer)
			viewer.screen -= src

	qdel(src)

/datum/controller/subsystem/jobs/proc/show_location_blurb(client/show_blurb_to)
	PRIVATE_PROC(TRUE)

	if(!show_blurb_to.mob)
		return

	var/obj/screen/text/blurb/location_blurb = new()
	location_blurb.blurb_text = uppertext("[GLOB.current_date_string], [station_time_timestamp()]\n[station_name()], [get_area_name(show_blurb_to.mob, TRUE)]")
	location_blurb.hold_for = 3 SECONDS
	location_blurb.appear_animation_duration = 1 SECONDS
	location_blurb.fade_animation_duration = 0.5 SECONDS

	location_blurb.show_to(show_blurb_to)

/datum/controller/subsystem/jobs/EquipRank(mob/living/carbon/human/human_to_equip, rank, joined_late)
	. = ..()
	INVOKE_ASYNC(src, TYPE_PROC_REF(/datum/controller/subsystem/jobs, show_location_blurb), human_to_equip.client)

/datum/controller/subsystem/ticker/reboot_helper(reason, end_string, delay)
	if(delay)
		INVOKE_ASYNC(src, TYPE_PROC_REF(/datum/controller/subsystem/ticker, show_server_restart_blurb), reason)

	. = ..()


/datum/controller/subsystem/ticker/proc/show_server_restart_blurb(reason)
	PRIVATE_PROC(TRUE)

	if(!length(GLOB.clients))
		return

	var/obj/screen/text/blurb/server_restart_blurp = new()
	server_restart_blurp.text_color = COLOR_RED
	server_restart_blurp.blurb_text = "Round is restarting...\n[reason]"
	server_restart_blurp.hold_for = 90 SECONDS
	server_restart_blurp.appear_animation_duration = 1 SECONDS
	server_restart_blurp.fade_animation_duration = 0.5 SECONDS

	server_restart_blurp.show_to(GLOB.clients)
