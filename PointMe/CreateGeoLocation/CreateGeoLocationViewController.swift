import UIKit
import YandexMapsMobile
import CoreLocation

final class CreateGeoLocationViewController: UIViewController {
    private lazy var bodySelectView: UIView = {
        let view: UIView = UIView()
        
        view.layer.cornerRadius = 10
        view.backgroundColor = .backgroundMapView
        view.layer.zPosition = 2
        
        return view
    }()
    
    private lazy var adressLabel: UILabel = {
        let label = UILabel()
        
        label.numberOfLines = 2
        
        return label
    }()
    
    private let mapView: YMKMapView = YMKMapView()
    
    private var placemark: YMKPlacemarkMapObject?
    
    private let locationManager = CLLocationManager()
    
    private let output: CreateGeoLocationViewOutput
    
    init(output: CreateGeoLocationViewOutput) {
        self.output = output

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

	override func viewDidLoad() {
		super.viewDidLoad()
        
        title = "Выберите место"
        view.backgroundColor = .backgroundPostViewController
        
        view.addSubview(mapView)
        view.addSubview(bodySelectView)
        
        bodySelectView.addSubview(adressLabel)
        
        bodySelectView.alpha = 0.0
        
        
        mapView.mapWindow.map.addInputListener(with: self)
        
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        setupLayout()
	}
    
    private func setupLayout() {
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mapView.leftAnchor.constraint(equalTo: view.leftAnchor),
            mapView.rightAnchor.constraint(equalTo: view.rightAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        bodySelectView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bodySelectView.heightAnchor.constraint(equalToConstant: 115),
            bodySelectView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20),
            bodySelectView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20),
            bodySelectView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -45)
        ])
        
        adressLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            adressLabel.heightAnchor.constraint(equalToConstant: adressLabel.font.pointSize * 2.5),
            adressLabel.leftAnchor.constraint(equalTo: bodySelectView.leftAnchor, constant: 20),
            adressLabel.rightAnchor.constraint(equalTo: bodySelectView.rightAnchor, constant: -20),
            adressLabel.topAnchor.constraint(equalTo: bodySelectView.topAnchor, constant: 10)
        ])
    }
    
    private func setMap(location: CLLocationCoordinate2D) {
        let point = YMKPoint(latitude: location.latitude, longitude: location.longitude)
        
        mapView.mapWindow.map.move(
            with: YMKCameraPosition(target: point, zoom: 15, azimuth: 0, tilt: 0),
            animationType: YMKAnimation(type: YMKAnimationType.smooth, duration: 1),
            cameraCallback: nil
        )
    }
}

extension CreateGeoLocationViewController: CreateGeoLocationViewInput {
    func showAdress(value: String) {
        adressLabel.text = value
    }
}

extension CreateGeoLocationViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        setMap(location: locValue)
        print("locations = \(locValue.latitude) \(locValue.longitude)")
    }
}

extension CreateGeoLocationViewController: YMKMapInputListener {
    func onMapTap(with map: YMKMap, point: YMKPoint) {}
    
    func onMapLongTap(with map: YMKMap, point: YMKPoint) {
        if placemark == nil {
            print("placemark == nil")
            UIView.animate(withDuration: 0.3) {
                self.bodySelectView.alpha = 1.0
            }
        }
        
        let mapObjects = mapView.mapWindow.map.mapObjects
        
        if let strongPlacemark = placemark {
            mapObjects.remove(with: strongPlacemark)
        }
        
        output.didTapPoint(latitude: point.latitude, longitude: point.longitude)
        
        guard let iconPin = UIImage(named: "pin") else { return }
        
        placemark = mapObjects.addPlacemark(with: YMKPoint(latitude: point.latitude, longitude: point.longitude))
        placemark?.opacity = 1
        placemark?.setIconWith(iconPin, style: YMKIconStyle(
            anchor: CGPoint(x: 0.5, y: 1) as NSValue,
            rotationType: YMKRotationType.noRotation.rawValue as NSNumber,
            zIndex: 0,
            flat: false,
            visible: true,
            scale: 1.0,
            tappableArea: YMKRect(min: CGPoint(x: 0, y: 0), max: CGPoint(x: 1, y: 1))
        ))
    }
}
