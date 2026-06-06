const std = @import("std");
const Snowflake = @import("../../core/snowflake.zig").Snowflake;
const Json = @import("../../core/json.zig");

const Root = @import("../mod.zig");
const InteractionType = Root.InteractionType;
const max_action_rows = Root.max_action_rows;
const max_row_components = Root.max_row_components;
const max_select_options = Root.max_select_options;
const max_command_options = Root.max_command_options;
const max_command_choices = Root.max_command_choices;
const max_custom_id_len = Root.max_custom_id_len;
const max_button_label_len = Root.max_button_label_len;
const max_select_placeholder_len = Root.max_select_placeholder_len;
const max_select_option_description_len = Root.max_select_option_description_len;
const max_text_input_label_len = Root.max_text_input_label_len;
const max_command_name_len = Root.max_command_name_len;
const max_choice_string_value_len = Root.max_choice_string_value_len;
const SelectOption = Root.SelectOption;
const Button = Root.Button;
const StringSelect = Root.StringSelect;
const AutoSelect = Root.AutoSelect;
const TextInput = Root.TextInput;
const TextDisplay = Root.TextDisplay;
const Thumbnail = Root.Thumbnail;
const Section = Root.Section;
const MediaGalleryItem = Root.MediaGalleryItem;
const MediaGallery = Root.MediaGallery;
const FileComponent = Root.FileComponent;
const Separator = Root.Separator;
const Container = Root.Container;
const Component = Root.Component;
const CommandChoice = Root.CommandChoice;
const ApplicationCommandOption = Root.ApplicationCommandOption;
const ParsedInteraction = Root.ParsedInteraction;
const CommandRoute = Root.CommandRoute;
const ComponentRoute = Root.ComponentRoute;
const Middleware = Root.Middleware;
const InteractionRouter = Root.InteractionRouter;
const InteractionRouterBuilder = Root.InteractionRouterBuilder;
const parsedHandler = Root.parsedHandler;
const middlewareHandler = Root.middlewareHandler;
const parseInteraction = Root.parseInteraction;
const ApplicationCommand = Root.ApplicationCommand;
const ApplicationCommandAnnotation = Root.ApplicationCommandAnnotation;
const ApplicationCommandModule = Root.ApplicationCommandModule;
const ApplicationCommandManifest = Root.ApplicationCommandManifest;
const ApplicationCommandRegistry = Root.ApplicationCommandRegistry;
const EditApplicationCommand = Root.EditApplicationCommand;

test "interaction router dispatches commands autocomplete components and modals" {
    const State = struct {
        command: bool = false,
        autocomplete: bool = false,
        component: bool = false,
        modal: bool = false,

        pub fn onCommand(self: *@This(), interaction: *const ParsedInteraction) !void {
            try std.testing.expectEqual(InteractionType.application_command, interaction.interaction.type);
            try std.testing.expectEqualStrings("echo", interaction.data.?.name);
            try std.testing.expectEqualStrings("hello", try interaction.data.?.getString("text"));
            self.command = true;
        }

        pub fn onAutocomplete(self: *@This(), interaction: *const ParsedInteraction) !void {
            try std.testing.expectEqual(InteractionType.application_command_autocomplete, interaction.interaction.type);
            try std.testing.expectEqualStrings("echo", interaction.data.?.name);
            self.autocomplete = true;
        }

        pub fn onComponent(self: *@This(), interaction: *const ParsedInteraction) !void {
            try std.testing.expectEqual(InteractionType.message_component, interaction.interaction.type);
            try std.testing.expectEqualStrings("confirm", interaction.component_data.?.custom_id);
            self.component = true;
        }

        pub fn onModal(self: *@This(), interaction: *const ParsedInteraction) !void {
            try std.testing.expectEqual(InteractionType.modal_submit, interaction.interaction.type);
            try std.testing.expectEqualStrings("profile_modal", interaction.component_data.?.custom_id);
            self.modal = true;
        }
    };

    var state = State{};
    const commands = [_]CommandRoute{
        .{ .name = "echo", .handler = parsedHandler(&state, State.onCommand) },
    };
    const autocomplete = [_]CommandRoute{
        .{ .name = "echo", .handler = parsedHandler(&state, State.onAutocomplete) },
    };
    const components = [_]ComponentRoute{
        .{ .custom_id = "confirm", .handler = parsedHandler(&state, State.onComponent) },
    };
    const modals = [_]ComponentRoute{
        .{ .custom_id = "profile_modal", .handler = parsedHandler(&state, State.onModal) },
    };
    const router = InteractionRouter{
        .commands = &commands,
        .autocomplete = &autocomplete,
        .components = &components,
        .modals = &modals,
    };

    var command = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"echo\",\"type\":1,\"options\":[{\"name\":\"text\",\"type\":3,\"value\":\"hello\"}]}}",
    );
    defer command.deinit();
    try std.testing.expect(try router.dispatch(&command));

    var autocomplete_interaction = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":4,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"echo\",\"type\":1}}",
    );
    defer autocomplete_interaction.deinit();
    try std.testing.expect(try router.dispatch(&autocomplete_interaction));

    var component = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"data\":{\"custom_id\":\"confirm\",\"component_type\":2}}",
    );
    defer component.deinit();
    try std.testing.expect(try router.dispatch(&component));

    var modal = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":5,\"token\":\"tok\",\"data\":{\"custom_id\":\"profile_modal\",\"components\":[]}}",
    );
    defer modal.deinit();
    try std.testing.expect(try router.dispatch(&modal));

    var unknown = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"missing\",\"type\":1}}",
    );
    defer unknown.deinit();
    try std.testing.expect(!try router.dispatch(&unknown));

    try std.testing.expect(state.command);
    try std.testing.expect(state.autocomplete);
    try std.testing.expect(state.component);
    try std.testing.expect(state.modal);
}

test "interaction router builder registers routes incrementally" {
    const State = struct {
        command: usize = 0,
        component: usize = 0,
        modal: usize = 0,
        fallback: usize = 0,

        pub fn onCommand(self: *@This(), interaction: *const ParsedInteraction) !void {
            try std.testing.expectEqualStrings("ping", interaction.data.?.name);
            self.command += 1;
        }

        pub fn onComponent(self: *@This(), interaction: *const ParsedInteraction) !void {
            try std.testing.expect(std.mem.startsWith(u8, interaction.component_data.?.custom_id, "menu:"));
            self.component += 1;
        }

        pub fn onModal(self: *@This(), interaction: *const ParsedInteraction) !void {
            try std.testing.expectEqualStrings("profile", interaction.component_data.?.custom_id);
            self.modal += 1;
        }

        pub fn onFallback(self: *@This(), _: *const ParsedInteraction) !void {
            self.fallback += 1;
        }
    };

    var state = State{};
    var builder = InteractionRouterBuilder.init(std.testing.allocator);
    defer builder.deinit();

    try builder.command("ping", parsedHandler(&state, State.onCommand));
    try builder.componentPrefix("menu:", parsedHandler(&state, State.onComponent));
    try builder.modal("profile", parsedHandler(&state, State.onModal));
    builder.fallbackTo(parsedHandler(&state, State.onFallback));
    const router = builder.router();

    var command = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"ping\",\"type\":1}}",
    );
    defer command.deinit();
    try std.testing.expect(try router.dispatch(&command));

    var component = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"data\":{\"custom_id\":\"menu:next\",\"component_type\":2}}",
    );
    defer component.deinit();
    try std.testing.expect(try router.dispatch(&component));

    var modal = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":5,\"token\":\"tok\",\"data\":{\"custom_id\":\"profile\",\"components\":[]}}",
    );
    defer modal.deinit();
    try std.testing.expect(try router.dispatch(&modal));

    var unknown = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"unknown\",\"type\":1}}",
    );
    defer unknown.deinit();
    try std.testing.expect(try router.dispatch(&unknown));

    try std.testing.expectEqual(@as(usize, 1), state.command);
    try std.testing.expectEqual(@as(usize, 1), state.component);
    try std.testing.expectEqual(@as(usize, 1), state.modal);
    try std.testing.expectEqual(@as(usize, 1), state.fallback);
}

test "application command registry pairs definitions with router routes" {
    const State = struct {
        calls: usize = 0,

        pub fn onPing(self: *@This(), interaction: *const ParsedInteraction) !void {
            try std.testing.expectEqualStrings("ping", interaction.data.?.name);
            self.calls += 1;
        }
    };

    var state = State{};
    var registry = ApplicationCommandRegistry.init(std.testing.allocator);
    defer registry.deinit();

    try registry.addCommandRoute(
        ApplicationCommand.chatInput("ping", "Replies with pong"),
        parsedHandler(&state, State.onPing),
    );
    try std.testing.expectEqual(@as(usize, 1), registry.definitions().len);

    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();
    try registry.writeDefinitionsJson(&out.writer);
    try std.testing.expectEqualStrings(
        "[{\"name\":\"ping\",\"description\":\"Replies with pong\",\"type\":1}]",
        out.written(),
    );

    var command = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"ping\",\"type\":1}}",
    );
    defer command.deinit();
    try std.testing.expect(try registry.router().dispatch(&command));
    try std.testing.expectEqual(@as(usize, 1), state.calls);
}

test "application command module registers command autocomplete and components" {
    const State = struct {
        command: usize = 0,
        autocomplete: usize = 0,
        component: usize = 0,

        pub fn onCommand(self: *@This(), _: *const ParsedInteraction) !void {
            self.command += 1;
        }

        pub fn onAutocomplete(self: *@This(), _: *const ParsedInteraction) !void {
            self.autocomplete += 1;
        }

        pub fn onComponent(self: *@This(), _: *const ParsedInteraction) !void {
            self.component += 1;
        }
    };

    var state = State{};
    const component_routes = [_]ComponentRoute{
        .{ .custom_id = "module:", .match = .prefix, .handler = parsedHandler(&state, State.onComponent) },
    };
    const module = ApplicationCommandModule
        .init(ApplicationCommand.chatInput("module", "Module command"), parsedHandler(&state, State.onCommand))
        .withAutocomplete(parsedHandler(&state, State.onAutocomplete))
        .withComponents(&component_routes);

    var registry = ApplicationCommandRegistry.init(std.testing.allocator);
    defer registry.deinit();
    try module.register(&registry);

    var command = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"module\",\"type\":1}}",
    );
    defer command.deinit();
    try std.testing.expect(try registry.router().dispatch(&command));

    var autocomplete = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":4,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"module\",\"type\":1}}",
    );
    defer autocomplete.deinit();
    try std.testing.expect(try registry.router().dispatch(&autocomplete));

    var component = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"data\":{\"custom_id\":\"module:next\",\"component_type\":2}}",
    );
    defer component.deinit();
    try std.testing.expect(try registry.router().dispatch(&component));

    try std.testing.expectEqual(@as(usize, 1), state.command);
    try std.testing.expectEqual(@as(usize, 1), state.autocomplete);
    try std.testing.expectEqual(@as(usize, 1), state.component);
}

test "application command manifest registers multiple modules" {
    const State = struct {
        calls: usize = 0,

        pub fn onAny(self: *@This(), _: *const ParsedInteraction) !void {
            self.calls += 1;
        }
    };

    var state = State{};
    const modules = [_]ApplicationCommandModule{
        ApplicationCommandModule.init(ApplicationCommand.chatInput("one", "First command"), parsedHandler(&state, State.onAny)),
        ApplicationCommandModule.init(ApplicationCommand.chatInput("two", "Second command"), parsedHandler(&state, State.onAny)),
    };
    const manifest = ApplicationCommandManifest.init(&modules);

    var registry = ApplicationCommandRegistry.init(std.testing.allocator);
    defer registry.deinit();
    try manifest.register(&registry);
    try std.testing.expectEqual(@as(usize, 2), registry.definitions().len);

    var one = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"one\",\"type\":1}}",
    );
    defer one.deinit();
    try std.testing.expect(try registry.router().dispatch(&one));

    var two = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"two\",\"type\":1}}",
    );
    defer two.deinit();
    try std.testing.expect(try registry.router().dispatch(&two));
    try std.testing.expectEqual(@as(usize, 2), state.calls);
}

test "application command annotations build definitions and modules" {
    const State = struct {
        calls: usize = 0,

        pub fn onRun(self: *@This(), interaction: *const ParsedInteraction) !void {
            try std.testing.expectEqualStrings("annotated", interaction.data.?.name);
            self.calls += 1;
        }
    };

    var state = State{};
    const options = [_]ApplicationCommandOption{
        ApplicationCommandOption.string("target", "Target name", true),
    };
    const annotation = ApplicationCommandAnnotation
        .slash("annotated", "Annotated command", parsedHandler(&state, State.onRun))
        .withOptions(&options)
        .withDMPermission(false);

    const definition = annotation.command();
    try std.testing.expectEqualStrings("annotated", definition.name);
    try std.testing.expectEqual(@as(usize, 1), definition.options.len);
    try std.testing.expectEqual(@as(?bool, false), definition.dm_permission);

    var registry = ApplicationCommandRegistry.init(std.testing.allocator);
    defer registry.deinit();
    try annotation.register(&registry);

    var interaction = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"annotated\",\"type\":1}}",
    );
    defer interaction.deinit();
    try std.testing.expect(try registry.router().dispatch(&interaction));
    try std.testing.expectEqual(@as(usize, 1), state.calls);
}

test "string select validate rejects option overflow at the limit boundary" {
    const at_limit = [_]SelectOption{SelectOption.init("l", "v")} ** max_select_options;
    try StringSelect.init("menu", &at_limit).validate();

    const over_limit = [_]SelectOption{SelectOption.init("l", "v")} ** (max_select_options + 1);
    try std.testing.expectError(error.TooManySelectOptions, StringSelect.init("menu", &over_limit).validate());
}

test "component layout validate enforces row and per-row component limits" {
    const button = Component{ .button = Button.primary("id", "Label") };

    const full_row_children = [_]Component{button} ** max_row_components;
    const full_row = Component.actionRow(&full_row_children);
    const max_rows = [_]Component{full_row} ** max_action_rows;
    try Component.validateLayout(&max_rows);

    const overfull_children = [_]Component{button} ** (max_row_components + 1);
    const overfull_row = [_]Component{Component.actionRow(&overfull_children)};
    try std.testing.expectError(error.TooManyRowComponents, Component.validateLayout(&overfull_row));

    const single_child = [_]Component{button};
    const slim_row = Component.actionRow(&single_child);
    const too_many_rows = [_]Component{slim_row} ** (max_action_rows + 1);
    try std.testing.expectError(error.TooManyActionRows, Component.validateLayout(&too_many_rows));
}

test "component layout validate walks nested string select option limits" {
    const over_limit = [_]SelectOption{SelectOption.init("l", "v")} ** (max_select_options + 1);
    const select = Component{ .string_select = StringSelect.init("menu", &over_limit) };
    const nested = [_]Component{select};
    const row = [_]Component{Component.actionRow(&nested)};
    try std.testing.expectError(error.TooManySelectOptions, Component.validateLayout(&row));
}

test "command validate rejects choice and option overflow recursively" {
    const at_choice_limit = [_]CommandChoice{CommandChoice.string("n", "v")} ** max_command_choices;
    try ApplicationCommandOption.string("opt", "desc", false).withChoices(&at_choice_limit).validate();

    const over_choices = [_]CommandChoice{CommandChoice.string("n", "v")} ** (max_command_choices + 1);
    try std.testing.expectError(
        error.TooManyCommandChoices,
        ApplicationCommandOption.string("opt", "desc", false).withChoices(&over_choices).validate(),
    );

    const over_options = [_]ApplicationCommandOption{ApplicationCommandOption.string("o", "d", false)} ** (max_command_options + 1);
    try std.testing.expectError(
        error.TooManyCommandOptions,
        ApplicationCommand.chatInput("cmd", "desc").withOptions(&over_options).validate(),
    );

    // A bad choice list nested inside a sub-command must be caught from the command root.
    const bad_child = ApplicationCommandOption.string("inner", "d", false).withChoices(&over_choices);
    const group = ApplicationCommandOption.subCommand("sub", "d", &.{}).withOption(&bad_child);
    try std.testing.expectError(
        error.TooManyCommandChoices,
        ApplicationCommand.chatInput("cmd", "desc").withOption(&group).validate(),
    );
}

test "component validate enforces string length limits" {
    const long_id = "c" ** (max_custom_id_len + 1);
    try std.testing.expectError(error.CustomIdTooLong, (Button{ .custom_id = long_id, .label = "ok" }).validate());

    const long_label = "L" ** (max_button_label_len + 1);
    try std.testing.expectError(error.ButtonLabelTooLong, Button.primary("id", long_label).validate());

    const long_text_label = "L" ** (max_text_input_label_len + 1);
    try std.testing.expectError(error.TextInputLabelTooLong, TextInput.short("id", long_text_label).validate());

    const long_desc = "d" ** (max_select_option_description_len + 1);
    try std.testing.expectError(
        error.SelectOptionDescriptionTooLong,
        SelectOption.init("label", "value").withDescription(long_desc).validate(),
    );

    const long_placeholder = "p" ** (max_select_placeholder_len + 1);
    const opts = [_]SelectOption{SelectOption.init("a", "1")};
    try std.testing.expectError(
        error.SelectPlaceholderTooLong,
        StringSelect.init("menu", &opts).withPlaceholder(long_placeholder).validate(),
    );

    // min_values greater than max_values is rejected.
    try std.testing.expectError(
        error.SelectValueRangeInvalid,
        StringSelect.init("menu", &opts).withValueRange(3, 2).validate(),
    );
    try std.testing.expectError(
        error.SelectValueRangeInvalid,
        AutoSelect.user("picker").withValueRange(1, 30).validate(),
    );
}

test "command validate enforces name description and choice length rules" {
    const long_name = "n" ** (max_command_name_len + 1);
    try std.testing.expectError(error.CommandNameInvalid, ApplicationCommand.chatInput(long_name, "desc").validate());

    // Chat-input commands require a non-empty description.
    try std.testing.expectError(error.CommandDescriptionInvalid, ApplicationCommand.chatInput("ok", "").validate());

    // User and message commands must carry an empty description.
    try ApplicationCommand.user("Inspect").validate();
    try std.testing.expectError(
        error.CommandDescriptionInvalid,
        (ApplicationCommand{ .name = "Inspect", .description = "nope", .type = .user }).validate(),
    );

    const long_choice = "v" ** (max_choice_string_value_len + 1);
    const choices = [_]CommandChoice{CommandChoice.string("name", long_choice)};
    const option = ApplicationCommandOption.string("opt", "desc", false).withChoices(&choices);
    try std.testing.expectError(error.ChoiceValueTooLong, option.validate());

    // A well-formed command tree validates cleanly.
    const good_choices = [_]CommandChoice{CommandChoice.string("Public", "public")};
    const good_option = ApplicationCommandOption.string("visibility", "Who sees it", true).withChoices(&good_choices);
    try ApplicationCommand.chatInput("echo", "Echoes text").withOption(&good_option).validate();
}

test "components v2 builders stream expected JSON" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    const section_text = [_]TextDisplay{TextDisplay.init("Body")};
    const gallery_items = [_]MediaGalleryItem{MediaGalleryItem.init("https://cdn/a.png")};
    const children = [_]Component{
        .{ .text_display = TextDisplay.init("# Title") },
        .{ .section = Section.withThumbnail(&section_text, Thumbnail.init("https://cdn/x.png").withDescription("art")) },
        .{ .media_gallery = MediaGallery.init(&gallery_items) },
        .{ .separator = Separator.init().withSpacing(.large) },
        .{ .file = FileComponent.init("attachment://a.txt") },
    };
    const component = Component{ .container = Container.init(&children).withAccentColor(0x5865F2) };
    try component.writeJson(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"type\":17,\"components\":[" ++
            "{\"type\":10,\"content\":\"# Title\"}," ++
            "{\"type\":9,\"components\":[{\"type\":10,\"content\":\"Body\"}],\"accessory\":{\"type\":11,\"media\":{\"url\":\"https://cdn/x.png\"},\"description\":\"art\"}}," ++
            "{\"type\":12,\"items\":[{\"media\":{\"url\":\"https://cdn/a.png\"}}]}," ++
            "{\"type\":14,\"spacing\":2}," ++
            "{\"type\":13,\"file\":{\"url\":\"attachment://a.txt\"}}" ++
            "],\"accent_color\":5793266}",
        out.written(),
    );
}

test "components v2 validate enforces section and gallery limits" {
    const four_texts = [_]TextDisplay{TextDisplay.init("t")} ** 4;
    const bad_section = Component{ .section = Section.withButton(&four_texts, Button.primary("a", "b")) };
    try std.testing.expectError(error.SectionComponentCountInvalid, bad_section.validate());

    const no_items = [_]MediaGalleryItem{};
    const empty_gallery = Component{ .media_gallery = MediaGallery.init(&no_items) };
    try std.testing.expectError(error.MediaGalleryItemCountInvalid, empty_gallery.validate());

    // A container surfaces a nested child's violation.
    const eleven = [_]MediaGalleryItem{MediaGalleryItem.init("u")} ** 11;
    const inner = [_]Component{.{ .media_gallery = MediaGallery.init(&eleven) }};
    const container = Component{ .container = Container.init(&inner) };
    try std.testing.expectError(error.MediaGalleryItemCountInvalid, container.validate());

    const one_text = [_]TextDisplay{TextDisplay.init("ok")};
    const good = Component{ .section = Section.withThumbnail(&one_text, Thumbnail.init("https://cdn/x.png")) };
    try good.validate();
}

test "interaction router supports middleware prefix routes and fallback" {
    const State = struct {
        seen: usize = 0,
        prefix_hits: usize = 0,
        fallback_hits: usize = 0,
        allow: bool = true,

        pub fn guard(self: *@This(), interaction: *const ParsedInteraction) !bool {
            _ = interaction;
            self.seen += 1;
            return self.allow;
        }

        pub fn onVote(self: *@This(), interaction: *const ParsedInteraction) !void {
            _ = interaction;
            self.prefix_hits += 1;
        }

        pub fn onFallback(self: *@This(), interaction: *const ParsedInteraction) !void {
            _ = interaction;
            self.fallback_hits += 1;
        }
    };

    var state = State{};
    const middleware = [_]Middleware{middlewareHandler(&state, State.guard)};
    const components = [_]ComponentRoute{
        .{ .custom_id = "vote:", .handler = parsedHandler(&state, State.onVote), .match = .prefix },
    };
    const router = InteractionRouter{
        .components = &components,
        .middleware = &middleware,
        .fallback = parsedHandler(&state, State.onFallback),
    };

    // Prefix route: custom_id "vote:yes" matches the "vote:" prefix route.
    var vote = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"data\":{\"custom_id\":\"vote:yes\",\"component_type\":2}}",
    );
    defer vote.deinit();
    try std.testing.expect(try router.dispatch(&vote));
    try std.testing.expectEqual(@as(usize, 1), state.prefix_hits);
    try std.testing.expectEqual(@as(usize, 1), state.seen);

    // Unmatched component falls through to the fallback handler.
    var other = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"data\":{\"custom_id\":\"nope\",\"component_type\":2}}",
    );
    defer other.deinit();
    try std.testing.expect(try router.dispatch(&other));
    try std.testing.expectEqual(@as(usize, 1), state.fallback_hits);

    // Middleware halt: no route or fallback runs, and dispatch returns false.
    state.allow = false;
    var halted = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":3,\"token\":\"tok\",\"data\":{\"custom_id\":\"vote:no\",\"component_type\":2}}",
    );
    defer halted.deinit();
    try std.testing.expect(!try router.dispatch(&halted));
    try std.testing.expectEqual(@as(usize, 1), state.prefix_hits);
    try std.testing.expectEqual(@as(usize, 1), state.fallback_hits);
}

test "parse autocomplete focused option and resolved context-menu target" {
    var autocomplete = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":4,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"search\",\"type\":1,\"options\":[{\"name\":\"scope\",\"type\":3,\"value\":\"a\"},{\"name\":\"query\",\"type\":3,\"value\":\"par\",\"focused\":true}]}}",
    );
    defer autocomplete.deinit();
    const focused = autocomplete.data.?.focusedOption().?;
    try std.testing.expectEqualStrings("query", focused.name);
    try std.testing.expectEqualStrings("par", try focused.getString());

    // USER context-menu command: target_id resolves into resolved.users.
    var context = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"Profile\",\"type\":2,\"target_id\":\"42\",\"resolved\":{\"users\":{\"42\":{\"id\":\"42\",\"username\":\"ada\"}}}}}",
    );
    defer context.deinit();
    const data = context.data.?;
    try std.testing.expectEqual(Snowflake.init(42), data.target_id.?);
    try std.testing.expect(data.focusedOption() == null);

    const target = data.targetUser().?;
    try std.testing.expectEqualStrings("ada", target.object.get("username").?.string);
    try std.testing.expect(data.resolved.user(Snowflake.init(99)) == null);
    try std.testing.expect(data.targetMessage() == null);
}

test "application command writes integration types and contexts" {
    var out = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer out.deinit();

    try ApplicationCommand.chatInput("deploy", "Deploy")
        .withIntegrationTypes(&.{ .guild_install, .user_install })
        .withContexts(&.{ .guild, .bot_dm, .private_channel })
        .writeJson(&out.writer);
    try std.testing.expectEqualStrings(
        "{\"name\":\"deploy\",\"description\":\"Deploy\",\"type\":1,\"integration_types\":[0,1],\"contexts\":[0,1,2]}",
        out.written(),
    );

    var edit = std.Io.Writer.Allocating.init(std.testing.allocator);
    defer edit.deinit();
    try EditApplicationCommand.init()
        .withIntegrationTypes(&.{.user_install})
        .writeJson(&edit.writer);
    try std.testing.expectEqualStrings("{\"integration_types\":[1]}", edit.written());
}

test "resolved typed user and role views" {
    var context = try parseInteraction(
        std.testing.allocator,
        "{\"id\":\"1\",\"application_id\":\"2\",\"type\":2,\"token\":\"tok\",\"data\":{\"id\":\"5\",\"name\":\"Promote\",\"type\":2,\"target_id\":\"42\",\"resolved\":{\"users\":{\"42\":{\"id\":\"42\",\"username\":\"ada\",\"global_name\":\"Ada L\",\"bot\":true,\"public_flags\":64}},\"roles\":{\"7\":{\"id\":\"7\",\"name\":\"Admins\",\"color\":255,\"hoist\":true,\"position\":3,\"permissions\":\"8\",\"managed\":false,\"mentionable\":true}}}}}",
    );
    defer context.deinit();
    const resolved = context.data.?.resolved;

    const user = (try resolved.resolvedUser(Snowflake.init(42))).?;
    try std.testing.expectEqualStrings("ada", user.username);
    try std.testing.expectEqualStrings("Ada L", user.displayName());
    try std.testing.expect(user.bot);
    try std.testing.expectEqual(@as(?u32, 64), user.public_flags);
    try std.testing.expect((try resolved.resolvedUser(Snowflake.init(99))) == null);

    const role = (try resolved.resolvedRole(Snowflake.init(7))).?;
    try std.testing.expectEqualStrings("Admins", role.name);
    try std.testing.expectEqual(@as(u24, 255), role.color);
    try std.testing.expect(role.hoist);
    try std.testing.expectEqual(@as(u64, 8), role.permissions);
    try std.testing.expect(role.mentionable);
}
