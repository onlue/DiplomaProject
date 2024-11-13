import MapKit
import SDWebImageSwiftUI
import SwiftUI
import CoreLocation

struct point: Identifiable{
    var id = UUID()
    var name: String
    var desc: String
    var image: String
    var cords: CLLocationCoordinate2D
    
    init( name: String, desc: String, image: String, cords: CLLocationCoordinate2D) {
        self.name = name
        self.desc = desc
        self.image = image
        self.cords = cords
    }
}

class MyAnnotation: NSObject, MKAnnotation {
    let title: String?
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let imageName: String
    
    init(title: String?, subtitle: String?, coordinate: CLLocationCoordinate2D, imageName: String) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.imageName = imageName
    }
    
    var markerTintColor: UIColor  {
        return UIColor.blue
    }
    
    var image: UIImage? {
        return UIImage(systemName: imageName)
    }
}

class UserAnnotation: NSObject, MKAnnotation {
    let title: String?
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    let imageUrl: String
    
    init(title: String?, subtitle: String?, coordinate: CLLocationCoordinate2D, imageUrl: String) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.imageUrl = imageUrl
    }
    
    var markerTintColor: UIColor {
        return UIColor.red
    }
    
    func loadImage(completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: imageUrl) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error loading image: \(error)")
                completion(nil)
                return
            }
            
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(nil)
            }
        }.resume()
    }
}

class MyAnnotationView: MKAnnotationView {
    override var annotation: MKAnnotation? {
        didSet {
            guard let annotation = annotation as? MyAnnotation else { return }
            image = UIImage(systemName: annotation.imageName)
        }
    }
}

class UserAnnotationView: MKMarkerAnnotationView {
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        
        // Настройка внешнего вида пина
        canShowCallout = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var annotation: MKAnnotation? {
        willSet {
            guard let userAnnotation = newValue as? UserAnnotation else { return }
            
            // Установка изображения на пин
            if let imageUrl = URL(string: userAnnotation.imageUrl) {
                SDWebImageManager.shared.loadImage(with: imageUrl, options: [], progress: nil) { [weak self] (image, _, _, _, _, _) in
                    if let image = image {
                        // Пропорциональное уменьшение размера изображения
                        let aspectRatio = image.size.width / image.size.height
                        let scaledSize = CGSize(width: 100 * aspectRatio, height: 100)
                        let scaledImage = image.sd_resizedImage(with: scaledSize, scaleMode: .aspectFit)
                        
                        DispatchQueue.main.async {
                            // Проверяем, что аннотация все еще активная
                            if self?.annotation === userAnnotation {
                                self?.detailCalloutAccessoryView = UIImageView(image: scaledImage)
                                self?.glyphImage = UIImage(systemName: "person.fill")
                            }
                        }
                    }
                }
            }
        }
    }
}





struct MapView: UIViewRepresentable {
    
    var mapView = MKMapView()
    
    var family: String
    
    private var pointArray = [point]()
    
    var canUpdateLocation: Bool
    
    @State private var isMarkerViewPresented = false
    
    internal init(family: String, canUpdateLocation: Bool){
        self.family = family
        self.canUpdateLocation = canUpdateLocation
    }
    
    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        context.coordinator.locationManager.requestWhenInUseAuthorization()
        context.coordinator.locationManager.startUpdatingLocation()
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate {
        var parent: MapView
        let locationManager = CLLocationManager()
        var mapView: MKMapView
        var lastUpdateTimestamp: TimeInterval?
        
        var userAnnotation: UserAnnotation?
        
        var pointsAnnotaion = [MyAnnotation]()
        var userPointsArray = [UserAnnotation]()
        
        init(parent: MapView, mapView: MKMapView) {
            self.parent = parent
            self.mapView = mapView
            super.init()
            self.getFamilyPoints()
            self.getUserPoints()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            mapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addAnnotation)))
        }
        
        @objc func addAnnotation(sender: UITapGestureRecognizer) {
            let location = sender.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            print(coordinate)
            let userDefaults = UserDefaults.standard
            userDefaults.set(coordinate.latitude, forKey: "latitude")
            userDefaults.set(coordinate.longitude, forKey: "longitude")
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            if parent.canUpdateLocation{
                let now = Date().timeIntervalSince1970
                if let lastUpdateTimestamp = lastUpdateTimestamp, now - lastUpdateTimestamp < 15.0 {
                    return
                }
                self.lastUpdateTimestamp = now
                
                if let location = locations.last {
                    let userLocation = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                    if let userAnnotation = self.userAnnotation {
                        self.mapView.removeAnnotation(userAnnotation)
                    }
                    let annotation = UserAnnotation(title: "Вы", subtitle: "Находитесь здесь", coordinate: userLocation, imageUrl: FireBaseManager.shared.currentUser?.profileImageUrl ?? "1")
                    self.mapView.addAnnotation(annotation)
                    self.userAnnotation = annotation
                    
                    let data = ["latitude": userLocation.latitude, "longitude": userLocation.longitude, "image": FireBaseManager.shared.currentUser?.profileImageUrl ?? "", "name": FireBaseManager.shared.currentUser?.email.replacingOccurrences(of: "@gmail.com", with: "") ?? "", "usId": FireBaseManager.shared.currentUser?.uid ?? "-1"] as [String : Any]
                    
                    FireBaseManager.shared.firestore
                        .collection("families_location")
                        .document(parent.family)
                        .collection("points")
                        .document(FireBaseManager.shared.currentUser?.uid ?? "-1")
                        .setData(data){ error in
                            if let error = error{
                                print(error)
                                return
                            }
                        }
                }
            }
            else{
                print("Выключено")
            }
        }
        
        func getUserPoints(){
            FireBaseManager.shared.firestore.collection("families_location")
                .document(parent.family)
                .collection("points")
                .addSnapshotListener{querySnapshot, error in
                    if let error = error {
                        print(error)
                        return
                    }
                    
                    guard let snapshot = querySnapshot else {
                        if let error = error {
                            print("Error fetching tasks: \(error)")
                        }
                        return
                    }
                    
                    let existingAnnotations = self.mapView.annotations.filter { $0 is UserAnnotation && $0.title != "Вы"}
                    self.mapView.removeAnnotations(existingAnnotations)
                    print(existingAnnotations.count, "Количество пользователей")
                    
                    for user in snapshot.documents{
                        let latitude = user.data()["latitude"] as? Double ?? 0.0
                        let longitude = user.data()["longitude"] as? Double ?? 0.0
                        let coords = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        self.parent.mapView.addAnnotation(UserAnnotation(title: (user.data()["name"] as? String ?? ""), subtitle: "Член семьи", coordinate: coords, imageUrl: user.data()["image"] as! String))
                        print(user.data())
                    }
                }
        }
        
        func getFamilyPoints() {
            FireBaseManager.shared.firestore.collection("points")
                .document(parent.family)
                .collection("points")
                .addSnapshotListener { querySnapshot, error in
                    if let error = error {
                        print(error)
                        return
                    }
                    
                    guard let snapshot = querySnapshot else {
                        if let error = error {
                            print("Error fetching tasks: \(error)")
                        }
                        return
                    }
                    
                    self.parent.pointArray.removeAll()
                    
                    // Удаление существующих аннотаций с карты
                    let existingAnnotations = self.mapView.annotations.filter { $0 is MyAnnotation }
                    self.mapView.removeAnnotations(existingAnnotations)
                    
                    self.pointsAnnotaion.removeAll()
                    
                    for document in snapshot.documents {
                        let latitude = document.data()["latitude"] as? Double ?? 0.0
                        let longitude = document.data()["longitude"] as? Double ?? 0.0
                        let pointName = document.data()["pointName"] as? String ?? ""
                        let pointDesc = document.data()["pointDesc"] as? String ?? ""
                        let pointImage = document.data()["pointImage"] as? String ?? ""
                        let coords = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        self.parent.pointArray.append(.init(name: pointName, desc: pointDesc, image: pointImage, cords: coords))
                        let annotation = MyAnnotation(title: pointName, subtitle: pointDesc, coordinate: coords, imageName: pointImage)
                        self.pointsAnnotaion.append(annotation)
                    }
                    
                    // Добавление новых аннотаций на карту
                    self.mapView.addAnnotations(self.pointsAnnotaion)
                }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is UserAnnotation {
                let identifier = "UserAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? UserAnnotationView
                if annotationView == nil {
                    annotationView = UserAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                
                return annotationView
            }
            if let myAnnotation = annotation as? MyAnnotation {
                let identifier = "MyAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: myAnnotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = myAnnotation
                }
                
                annotationView?.markerTintColor = myAnnotation.markerTintColor
                annotationView?.glyphImage = myAnnotation.image
                annotationView?.glyphTintColor = .white
                annotationView?.titleVisibility = .visible
                
                return annotationView
            } else {
                return nil
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self, mapView: mapView)
    }
}

struct AddMarkerView: View {
    var familyName: String
    @Environment(\.presentationMode) var presentationMode
    @State private var name = ""
    @State private var description = ""
    @State private var selectedImage = ""
    var imagesArray = ["house", "building.columns", "building", "mappin.and.ellipse", "bag", "cart", "bandage"]
    
    var body: some View {
        NavigationView{
            VStack {
                TextField("Название", text: $name)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                
                TextField("Описание", text: $description)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                ScrollView(.horizontal, showsIndicators: false){
                    HStack{
                        ForEach(imagesArray, id: \.self) { imagename in
                            Button(action: {
                                self.selectedImage = imagename
                            }) {
                                Image(systemName: imagename)
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(.blue)
                                    .cornerRadius(15)
                            }
                        }
                    }
                }.padding()
               
                Button{
                    let userDefaults = UserDefaults.standard
                    if let latitude = userDefaults.value(forKey: "latitude") as? CLLocationDegrees,
                       let longitude = userDefaults.value(forKey: "longitude") as? CLLocationDegrees {
                        let savedCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        addPoint(pointName: name, pointDesc: description, pointImage: selectedImage, familyName: familyName, coordinates: savedCoordinate)
                        presentationMode.wrappedValue.dismiss()
                    }
                    else{
                        print("ошибка при создании геоточки")
                        return
                    }
                }label:{
                    HStack{
                        Spacer()
                        Text("Добавить").font(.system(size: 16, weight: .bold))
                        Spacer()
                    }.foregroundColor(.white)
                        .padding(.vertical)
                        .background(Color.blue)
                        .cornerRadius(32)
                        .padding(.horizontal)
                        .shadow(radius: 15)
                }
                Spacer()
            }
            .navigationTitle("Добавление точки")
            Spacer()
        }
    }
}

struct MapViewWrapper: View {
    var familyName: String
    var canUpdateLocation: Bool
    @State private var isPresented = false

    var body: some View {
        MapView(family: familyName, canUpdateLocation: canUpdateLocation)
            .sheet(isPresented: $isPresented) {
                AddMarkerView(familyName: self.familyName)
            }
            .onTapGesture {
                isPresented = true
            }
    }
}

 func addPoint(pointName: String, pointDesc: String, pointImage: String, familyName: String, coordinates: CLLocationCoordinate2D){
    if pointName.isEmpty || pointDesc.isEmpty || pointImage.isEmpty{
        print("Поле пустое")
        return
    }
    
    let data = ["pointName": pointName, "pointDesc": pointDesc, "pointImage": pointImage, "latitude": coordinates.latitude, "longitude": coordinates.longitude] as [String : Any]
    print(data)
    
    FireBaseManager.shared.firestore.collection("points")
        .document(familyName)
        .collection("points")
        .document()
        .setData(data){
            error in
            if let error = error{
                print(error)
                return
            }
        }
}
