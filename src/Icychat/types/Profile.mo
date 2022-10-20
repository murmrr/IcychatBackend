import Hash "mo:base/Hash";
import Principal "mo:base/Principal";

import ProfileUpdate "ProfileUpdate";

module {
  public type Profile = {
    userPrincipal : Principal;
    username : Text;
  };

  public func getDefault(userPrincipal0 : Principal) : Profile {
    return {
      userPrincipal = userPrincipal0;
      username = "";
    };
  };

  public func update(old : Profile, new : ProfileUpdate.ProfileUpdate) : Profile {
    return {
      userPrincipal = old.userPrincipal;
      username = new.username;
    };
  };
};
