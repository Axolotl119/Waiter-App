# Waiter App (demodidong)

Ứng dụng mẫu quản lý gọi món cho nhà hàng/quán ăn, dùng Flutter + Firebase:
- Đăng nhập/đăng ký với Firebase Auth (phân quyền Admin/Waiter)
- Quản trị bàn và món (Admin)
- Chọn bàn, thêm món vào giỏ, thanh toán (mock) và lưu Order vào Firestore (Waiter)
- Chạy đa nền tảng: Mobile, Web, Desktop

## Công nghệ
- Flutter (Material 3) — cấu hình theme tại [`core/app_theme.dart`](lib/core/app_theme.dart)
- Firebase Core, Auth, Firestore — cấu hình tại [`firebase_options.dart`](lib/firebase_options.dart)
- State: InheritedWidget + ChangeNotifier qua [`AppRepository`](lib/data/app_repository.dart)

## Cấu trúc thư mục (lib/)
- Core
  - [`core/constants.dart`](lib/core/constants.dart): hằng số, ví dụ `kRestaurantId`
  - [`core/firestore_paths.dart`](lib/core/firestore_paths.dart): đường dẫn collection (`FP`)
  - [`core/validators.dart`](lib/core/validators.dart): validator form
- Data
  - [`data/app_repository.dart`](lib/data/app_repository.dart): nguồn dữ liệu trung tâm, Auth + đồng bộ Firestore + giỏ hàng + checkout
  - [`data/providers.dart`](lib/data/providers.dart): Riverpod providers (AuthService, FirestoreService)
- Models
  - [`models/table_model.dart`](lib/models/table_model.dart), [`models/menu_item_model.dart`](lib/models/menu_item_model.dart), [`models/order_model.dart`](lib/models/order_model.dart), [`models/cart_item.dart`](lib/models/cart_item.dart), [`models/user.dart`](lib/models/user.dart)
- Services
  - [`services/auth_service.dart`](lib/services/auth_service.dart)
  - [`services/firestore_service.dart`](lib/services/firestore_service.dart)
- UI Screens
  - Auth: [`LoginScreen`](lib/screens/auth/login_screen.dart), [`RegisterScreen`](lib/screens/auth/register_screen.dart), [`AuthGate`](lib/screens/auth/auth_gate.dart)
  - Waiter: Chọn bàn [`SelectTableScreen`](lib/screens/tables/table_screen.dart), Menu [`MenuScreen`](lib/screens/waiter/menu_screen.dart), Giỏ hàng [`CartScreen`](lib/screens/cart/cart_screen.dart), Thành công [`OrderSuccessScreen`](lib/screens/success/order_success_screen.dart)
  - Admin: [`AdminDashboard`](lib/screens/admin/admin_dashboard.dart)
- Widget chung: [`AppDrawer`](lib/widgets/app_drawer.dart)
- App entry: [`main.dart`](lib/main.dart)

## Tính năng chính
- Auth
  - Đăng ký waiter: [`AppRepository.register`](lib/data/app_repository.dart)
  - Đăng nhập: [`AppRepository.login`](lib/data/app_repository.dart)
  - Đăng xuất: [`AppRepository.logout`](lib/data/app_repository.dart)
- Quản trị
  - Bàn: thêm/sửa/xóa qua [`AppRepository.addTable`](lib/data/app_repository.dart), [`AppRepository.updateTable`](lib/data/app_repository.dart), [`AppRepository.deleteTable`](lib/data/app_repository.dart)
  - Món: thêm/sửa/xóa qua [`AppRepository.addMenuItem`](lib/data/app_repository.dart), [`AppRepository.updateMenuItem`](lib/data/app_repository.dart), [`AppRepository.deleteMenuItem`](lib/data/app_repository.dart)
- Gọi món/Checkout
  - Quản lý giỏ: `addToCart`, `decreaseQty`, `removeFromCart`, `clearCart` trong [`AppRepository`](lib/data/app_repository.dart)
  - Thanh toán (mock) + lưu Firestore: [`AppRepository.checkout`](lib/data/app_repository.dart)
  - Luồng thay thế có giao dịch với bàn/đơn: [`FirestoreService.openOrderForTable`](lib/services/firestore_service.dart), [`FirestoreService.addItemToOrder`](lib/services/firestore_service.dart)

## Firestore schema (tham khảo)
- `restaurants/{rid}/tables/{tableId}`: `name`, `capacity`, `isAvailable`, `currentOrderId?`, `updatedAt`
- `restaurants/{rid}/menu_items/{itemId}`: `name`, `price`, `categoryId`, `updatedAt`
- `restaurants/{rid}/orders/{orderId}`: `tableId`, `waiterId`, `status`, `subtotal`, `discount`, `serviceCharge`, `tax`, `total`, `itemsCount`, `createdAt`, `updatedAt`
  - `items/{itemId}`: `menuItemId`, `name`, `price`, `qty`, `note`, `lineStatus`, `createdAt`, `updatedAt`
- `users/{uid}`: `email`, `role`

Đường dẫn được chuẩn hóa qua [`FP`](lib/core/firestore_paths.dart).

Lưu ý: Trong [`AppRepository.checkout`](lib/data/app_repository.dart) có để sẵn comment cập nhật trạng thái bàn (bạn có thể bật nếu cần đồng bộ “bàn đang dùng”).

## Yêu cầu
- Flutter SDK
- Tài khoản Firebase + Firestore đã bật
- Cấu hình Firebase trong [`firebase_options.dart`](lib/firebase_options.dart) (đã có sẵn; thay bằng dự án của bạn nếu cần)

## Chạy dự án
1. Cài dependencies:
   - Trên terminal VS Code: `flutter pub get`
2. Chạy:
   - Thiết bị mặc định: `flutter run`
   - Web: `flutter run -d chrome`
   - Windows: `flutter run -d windows` (đã cấu hình runner)

## Ghi chú bảo mật
- Nên cấu hình Firestore Security Rules theo `role` user (`users/{uid}.role`) để phân quyền Admin/Waiter.
- Không lưu plaintext password trong hồ sơ người dùng. Ứng dụng đã dùng Firebase Auth chuẩn.

## Giấy phép
Dự án mẫu phục vụ học tập và khởi tạo nhanh. Hãy kiểm tra và tinh chỉnh theo nhu cầu thực tế của bạn.
