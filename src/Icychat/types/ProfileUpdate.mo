import Text "mo:base/Text";

module {
  public type ProfileUpdate = {
    username : Text;
  };

  private let USERNAME_MAX_LENGTH : Nat = 16;

  private func validateUsername(username : Text) : Bool {
    if (username.size() > USERNAME_MAX_LENGTH) {
      return false;
    };

    return true;
  };

  public func validate(profileUpdate : ProfileUpdate) : Bool {
    if (not validateUsername(profileUpdate.username)) {
      return false;
    };

    return true;
  };
};
