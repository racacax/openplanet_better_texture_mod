/*
    Method to automatically disable a button when ModWork is loading
*/
bool DynamicButton(const string&in label, const vec2&in size = vec2 ( )) {
    UI::BeginDisabled(ModWorkLoading::displayModWorkLoading);
    auto button = UI::Button(label, size);
    UI::EndDisabled();
    return button;
}

/* Button with a secondary prompt to perform the requested operation */
dictionary confirmationButtons = {};
bool ConfirmationButton(const string&in label, const vec2&in size = vec2 ( ), const string &in confirmationText = "Are you sure to perform this operation ?") {
    auto button = UI::Button(label, size);
    if(button) {
        confirmationButtons.Set(label, true);
    }
    bool displayPrompt = false;
    confirmationButtons.Get(label, displayPrompt);
    bool returnValue = false;
    if(displayPrompt) {
        UI::Text(confirmationText);
        UI::BeginTable("confirmationButtons##" + label, 2, UI::TableFlags::SizingFixedFit);
        UI::TableNextRow();
        UI::TableNextColumn();
        UI::PushStyleColor(UI::Col::Button, vec4(0,0.5,1,1));
        if(UI::Button("Yes")) {
            confirmationButtons.Set(label, false);
            returnValue = true;
        }
        UI::TableNextColumn();
        if(UI::Button("No")) {
            confirmationButtons.Set(label, false);
        }
        UI::PopStyleColor(1);
        UI::EndTable();
    }
    return returnValue;
}