import '../../domain/model/authenticated_user.dart';
import '../resources/authenticated_user_resource.dart';

/// Translates IAM resources (JSON contract) into domain entities.
class AuthenticatedUserAssembler {
  AuthenticatedUserAssembler._();

  static AuthenticatedUser fromAuthenticatedResource(AuthenticatedUserResource resource) => AuthenticatedUser(
        id: resource.id,
        username: resource.username,
        role: resource.role,
        provider: resource.provider,
      );

  static AuthenticatedUser fromCurrentUserResource(CurrentUserResource resource) => AuthenticatedUser(
        id: resource.id,
        username: resource.username,
        role: resource.role,
        provider: resource.provider,
        email: resource.email,
      );
}
