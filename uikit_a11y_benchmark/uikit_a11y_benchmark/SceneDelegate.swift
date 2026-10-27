import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        let menuViewController = MenuViewController()
        let navigationController = UINavigationController(rootViewController: menuViewController)
        navigationController.navigationBar.prefersLargeTitles = false

        window.rootViewController = navigationController
        self.window = window
        window.makeKeyAndVisible()
    }
}
