import SwiftUI
import MapKit

// MARK: - Models
struct Ride: Identifiable {
    let id = UUID()
    let driver: User
    let from: Location
    let to: Location
    let departureTime: Date
    let availableSeats: Int
    let price: Double
    let rating: Double
    let status: RideStatus
}

enum RideStatus: String {
    case scheduled = "Scheduled"
    case inProgress = "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

struct Location: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let type: LocationType
}

enum LocationType {
    case university
    case metro
    case landmark
    case market
}

// MARK: - Message Models
struct Message: Identifiable {
    let id = UUID()
    let sender: User
    let content: String
    let timestamp: Date
    let isRead: Bool
    let ride: Ride?
}

struct Chat: Identifiable {
    let id = UUID()
    let participant: User
    let lastMessage: Message
    let unreadCount: Int
}

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            MyRidesView()
                .tabItem {
                    Label("My Rides", systemImage: "car.fill")
                }
                .tag(1)
            
            CreateRideView()
                .tabItem {
                    Label("Offer Ride", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            MessagesView()
                .tabItem {
                    Label("Messages", systemImage: "message.fill")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @State private var searchText = ""
    @State private var region = MKCoordinateRegion(
        // Default to Gautam Buddha University coordinates
        center: CLLocationCoordinate2D(latitude: 28.4235, longitude: 77.5401),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var showingFilters = false
    @State private var selectedFilter = "All"
    @State private var showingRideDetails = false
    @State private var selectedRide: Ride?
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    @State private var showingLocationPermissionAlert = false
    
    // Updated locations
    let commonLocations = [
        Location(name: "Gautam Buddha University", coordinate: CLLocationCoordinate2D(latitude: 28.4235, longitude: 77.5401), type: .university),
        Location(name: "Knowledge Park II Metro", coordinate: CLLocationCoordinate2D(latitude: 28.4729, longitude: 77.5064), type: .metro),
        Location(name: "Pari Chowk", coordinate: CLLocationCoordinate2D(latitude: 28.4676, longitude: 77.5116), type: .landmark),
        Location(name: "Alpha 1 Market", coordinate: CLLocationCoordinate2D(latitude: 28.4789, longitude: 77.5095), type: .market),
        Location(name: "Beta 1 Market", coordinate: CLLocationCoordinate2D(latitude: 28.4612, longitude: 77.5121), type: .market),
        Location(name: "Galgotias University", coordinate: CLLocationCoordinate2D(latitude: 28.4506, longitude: 77.4933), type: .university),
        Location(name: "Sharda University", coordinate: CLLocationCoordinate2D(latitude: 28.4730, longitude: 77.4850), type: .university),
        Location(name: "Alpha 2 Market", coordinate: CLLocationCoordinate2D(latitude: 28.4705, longitude: 77.5167), type: .market)
    ]
    
    // Sample rides with updated locations
    var sampleRides: [Ride] {
        [
            Ride(driver: User(id: "1", name: "Rahul Kumar", email: "rahul@gbu.ac.in", profileImage: nil),
                 from: commonLocations[0], // GBU
                 to: commonLocations[1],   // Knowledge Park Metro
                 departureTime: Date().addingTimeInterval(3600),
                 availableSeats: 3,
                 price: 50,
                 rating: 4.8,
                 status: .scheduled),
            Ride(driver: User(id: "2", name: "Priya Singh", email: "priya@gbu.ac.in", profileImage: nil),
                 from: commonLocations[0], // GBU
                 to: commonLocations[2],   // Pari Chowk
                 departureTime: Date().addingTimeInterval(7200),
                 availableSeats: 2,
                 price: 40,
                 rating: 4.9,
                 status: .scheduled)
        ]
    }
    
    var filteredRides: [Ride] {
        var rides = sampleRides
        
        // Apply text search filter
        if !searchText.isEmpty {
            rides = rides.filter { ride in
                ride.from.name.localizedCaseInsensitiveContains(searchText) ||
                ride.to.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply selected filter
        switch selectedFilter {
        case "Today":
            rides = rides.filter { Calendar.current.isDateInToday($0.departureTime) }
        case "Tomorrow":
            rides = rides.filter { Calendar.current.isDateInTomorrow($0.departureTime) }
        case "This Week":
            rides = rides.filter {
                Calendar.current.isDate($0.departureTime, equalTo: Date(), toGranularity: .weekOfYear)
            }
        case "Lowest Price":
            rides.sort { $0.price < $1.price }
        default:
            break
        }
        
        return rides
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map View with user tracking
                Map(coordinateRegion: $region,
                    showsUserLocation: true,
                    userTrackingMode: $userTrackingMode,
                    annotationItems: commonLocations) { location in
                    MapAnnotation(coordinate: location.coordinate) {
                        LocationAnnotationView(location: location)
                            .onTapGesture {
                                withAnimation {
                                    region.center = location.coordinate
                                }
                            }
                    }
                }
                .ignoresSafeArea()
                .onAppear(perform: checkLocationPermission)
                
                // Overlays
                VStack(spacing: 0) {
                    // Search and Location Controls
                    VStack(spacing: 16) {
                        // Search Bar and Filter
                        HStack(spacing: 12) {
                            // Search Bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                TextField("Search destination", text: $searchText)
                                    .autocapitalization(.none)
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            // Filter Button
                            Button(action: { showingFilters.toggle() }) {
                                Image(systemName: "slider.horizontal.3")
                                    .foregroundColor(.primary)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Quick Actions
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                QuickActionButton(title: "GBU", systemImage: "building.columns.fill") {
                                    withAnimation {
                                        region.center = commonLocations[0].coordinate
                                        region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                    }
                                }
                                
                                QuickActionButton(title: "Metro", systemImage: "train.side.front.car") {
                                    withAnimation {
                                        region.center = commonLocations[1].coordinate
                                        region.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                    }
                                }
                                
                                QuickActionButton(title: "Markets", systemImage: "cart.fill") {
                                    withAnimation {
                                        let markets = commonLocations.filter { $0.type == .market }
                                        if let firstMarket = markets.first {
                                            region.center = firstMarket.coordinate
                                            region.span = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                                        }
                                    }
                                }
                                
                                QuickActionButton(title: "My Location", systemImage: "location.fill") {
                                    userTrackingMode = .follow
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 60)
                    .background(
                        Color.white.opacity(0.95)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                    
                    // Location Suggestions
                    if !searchText.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(commonLocations.filter {
                                    $0.name.localizedCaseInsensitiveContains(searchText)
                                }) { location in
                                    Button(action: {
                                        searchText = location.name
                                        withAnimation {
                                            region.center = location.coordinate
                                            region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                        }
                                    }) {
                                        LocationSuggestionRow(location: location)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .background(Color.white)
                        .frame(maxHeight: 200)
                        .transition(.move(edge: .top))
                    }
                    
                    Spacer()
                    
                    // Available Rides
                    if !filteredRides.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(filteredRides) { ride in
                                    RideCard(ride: ride)
                                        .onTapGesture {
                                            selectedRide = ride
                                            showingRideDetails = true
                                        }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                        .background(
                            Color.white
                                .shadow(color: Color.black.opacity(0.1), radius: 10, y: -5)
                        )
                    } else {
                        Text("No rides available for this route")
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                            .padding(.bottom)
                    }
                }
            }
            .navigationTitle("Find a Ride")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingFilters) {
                FilterView(selectedFilter: $selectedFilter)
            }
            .sheet(isPresented: $showingRideDetails) {
                if let ride = selectedRide {
                    RideDetailView(ride: ride)
                }
            }
            .alert("Location Access Required", isPresented: $showingLocationPermissionAlert) {
                Button("Settings", role: .none) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable location access in Settings to use all features of the app.")
            }
        }
    }
    
    private func checkLocationPermission() {
        switch CLLocationManager().authorizationStatus {
        case .denied, .restricted:
            showingLocationPermissionAlert = true
        default:
            break
        }
    }
}

// MARK: - Ride Card View
struct RideCard: View {
    let ride: Ride
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Driver Info
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(ride.driver.name)
                        .font(.headline)
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", ride.rating))
                            .font(.subheadline)
                    }
                }
            }
            
            Divider()
            
            // Ride Details
            Group {
                LocationRow(color: .green, text: ride.from.name)
                LocationRow(color: .red, text: ride.to.name)
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.gray)
                        Text(formatDepartureTime(ride.departureTime))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Text("₹\(Int(ride.price))")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.accentColor)
                }
            }
            
            Button(action: {}) {
                Text("Request Ride")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 2)
        .frame(width: 300)
    }
    
    private func formatDepartureTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Filter View
struct FilterView: View {
    @Binding var selectedFilter: String
    @Environment(\.dismiss) var dismiss
    
    let filters = ["All", "Today", "Tomorrow", "This Week", "Lowest Price"]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filters, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                        dismiss()
                    }) {
                        HStack {
                            Text(filter)
                            Spacer()
                            if filter == selectedFilter {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Rides")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

// MARK: - Ride Detail View
struct RideDetailView: View {
    let ride: Ride
    @Environment(\.dismiss) var dismiss
    @State private var showingRequestConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Driver Info
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading) {
                            Text(ride.driver.name)
                                .font(.title2)
                                .bold()
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", ride.rating))
                                Text("• 50+ rides")
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    
                    // Ride Details
                    VStack(spacing: 15) {
                        DetailRow(icon: "calendar", title: "Date", detail: formatDate(ride.departureTime))
                        DetailRow(icon: "clock.fill", title: "Time", detail: formatTime(ride.departureTime))
                        DetailRow(icon: "person.2.fill", title: "Available Seats", detail: "\(ride.availableSeats)")
                        DetailRow(icon: "indianrupeesign.circle.fill", title: "Price per Seat", detail: "₹\(Int(ride.price))")
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // Route
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Route")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 30) {
                                LocationRow(color: .green, text: ride.from.name)
                                LocationRow(color: .red, text: ride.to.name)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Request Button
                    Button(action: {
                        showingRequestConfirmation = true
                    }) {
                        Text("Request Ride")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(15)
                    }
                    .padding()
                }
            }
            .navigationTitle("Ride Details")
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
            .alert("Confirm Request", isPresented: $showingRequestConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Confirm") {
                    // Handle ride request
                    dismiss()
                }
            } message: {
                Text("Would you like to request this ride for ₹\(Int(ride.price))?")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let detail: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(detail)
                .bold()
        }
        .padding(.horizontal)
    }
}

// MARK: - My Rides View
struct MyRidesView: View {
    @State private var selectedSegment = 0
    @State private var showingRideDetails = false
    @State private var selectedRide: Ride?
    let segments = ["Upcoming", "Past"]
    
    // Sample rides data
    let upcomingRides = [
        Ride(driver: User(id: "1", name: "Rahul Kumar", email: "rahul@gbu.ac.in", profileImage: nil),
             from: Location(name: "Gautam Buddha University", coordinate: CLLocationCoordinate2D(latitude: 28.4235, longitude: 77.5401), type: .university),
             to: Location(name: "Knowledge Park II Metro", coordinate: CLLocationCoordinate2D(latitude: 28.4729, longitude: 77.5064), type: .metro),
             departureTime: Date().addingTimeInterval(3600),
             availableSeats: 3,
             price: 50,
             rating: 4.8,
             status: .scheduled),
        Ride(driver: User(id: "2", name: "Priya Singh", email: "priya@gbu.ac.in", profileImage: nil),
             from: Location(name: "Gautam Buddha University", coordinate: CLLocationCoordinate2D(latitude: 28.4235, longitude: 77.5401), type: .university),
             to: Location(name: "Pari Chowk", coordinate: CLLocationCoordinate2D(latitude: 28.4676, longitude: 77.5116), type: .landmark),
             departureTime: Date().addingTimeInterval(7200),
             availableSeats: 2,
             price: 40,
             rating: 4.9,
             status: .inProgress)
    ]
    
    let pastRides = [
        Ride(driver: User(id: "3", name: "Amit Verma", email: "amit@gbu.ac.in", profileImage: nil),
             from: Location(name: "Knowledge Park II Metro", coordinate: CLLocationCoordinate2D(latitude: 28.4729, longitude: 77.5064), type: .metro),
             to: Location(name: "Gautam Buddha University", coordinate: CLLocationCoordinate2D(latitude: 28.4235, longitude: 77.5401), type: .university),
             departureTime: Date().addingTimeInterval(-86400),
             availableSeats: 4,
             price: 45,
             rating: 4.7,
             status: .completed)
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                // Custom Segment Control
                Picker("Rides", selection: $selectedSegment) {
                    ForEach(0..<segments.count) { index in
                        Text(segments[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedSegment == 0 {
                    UpcomingRidesView(rides: upcomingRides) { ride in
                        selectedRide = ride
                        showingRideDetails = true
                    }
                } else {
                    PastRidesView(rides: pastRides) { ride in
                        selectedRide = ride
                        showingRideDetails = true
                    }
                }
            }
            .navigationTitle("My Rides")
            .sheet(isPresented: $showingRideDetails) {
                if let ride = selectedRide {
                    RideDetailView(ride: ride)
                }
            }
        }
    }
}

struct UpcomingRidesView: View {
    let rides: [Ride]
    let onRideSelected: (Ride) -> Void
    
    var body: some View {
        if rides.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "car.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
                Text("No upcoming rides")
                    .font(.headline)
                Text("Book a ride to get started")
                    .foregroundColor(.gray)
            }
            .padding()
        } else {
            List {
                ForEach(rides) { ride in
                    RideRow(ride: ride)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onRideSelected(ride)
                        }
                }
            }
        }
    }
}

struct PastRidesView: View {
    let rides: [Ride]
    let onRideSelected: (Ride) -> Void
    
    var body: some View {
        if rides.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
                Text("No past rides")
                    .font(.headline)
            }
            .padding()
        } else {
            List {
                ForEach(rides) { ride in
                    RideRow(ride: ride)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onRideSelected(ride)
                        }
                }
            }
        }
    }
}

struct RideRow: View {
    let ride: Ride
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(formatDate(ride.departureTime))
                    .font(.headline)
                Spacer()
                Text(ride.status.rawValue)
                    .font(.caption)
                    .padding(5)
                    .background(backgroundColorForStatus(ride.status).opacity(0.2))
                    .cornerRadius(5)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 15) {
                    LocationRow(color: .green, text: ride.from.name)
                    LocationRow(color: .red, text: ride.to.name)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    if ride.status == .completed {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", ride.rating))
                        }
                    } else {
                        Text("\(ride.availableSeats) Seats")
                            .font(.caption)
                    }
                    Text("₹\(Int(ride.price))")
                        .font(.headline)
                        .foregroundColor(ride.status == .completed ? .gray : .accentColor)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today, " + formatTime(date)
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow, " + formatTime(date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: date)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func backgroundColorForStatus(_ status: RideStatus) -> Color {
        switch status {
        case .scheduled: return .blue
        case .inProgress: return .green
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
}

// MARK: - Create Ride View
struct CreateRideView: View {
    @State private var fromLocation = ""
    @State private var toLocation = ""
    @State private var date = Date()
    @State private var seats = 1
    @State private var price = ""
    @State private var notes = ""
    @State private var showingLocationSearch = false
    @State private var isEditingFromLocation = false
    @State private var isEditingToLocation = false
    @State private var showingConfirmation = false
    @State private var isRecurringRide = false
    @State private var recurringDays: Set<Int> = []
    
    let commonLocations = [
        "Delhi University North Campus",
        "IIT Delhi",
        "Delhi Metro - Vishwavidyalaya",
        "Connaught Place",
        "South Campus",
        "Nehru Place",
        "Lajpat Nagar",
        "Karol Bagh"
    ]
    
    var formattedPrice: Binding<String> {
        Binding(
            get: { price },
            set: { newValue in
                let filtered = newValue.filter { "0123456789".contains($0) }
                price = filtered
            }
        )
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Route")) {
                    Button(action: {
                        isEditingFromLocation = true
                        showingLocationSearch = true
                    }) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.green)
                            if fromLocation.isEmpty {
                                Text("From")
                                    .foregroundColor(.gray)
                            } else {
                                Text(fromLocation)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    Button(action: {
                        isEditingToLocation = true
                        showingLocationSearch = true
                    }) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                            if toLocation.isEmpty {
                                Text("To")
                                    .foregroundColor(.gray)
                            } else {
                                Text(toLocation)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
                
                Section(header: Text("Schedule")) {
                    DatePicker("Departure Time", selection: $date, in: Date()...)
                    
                    Toggle("Recurring Ride", isOn: $isRecurringRide)
                    
                    if isRecurringRide {
                        WeekdayPicker(selectedDays: $recurringDays)
                    }
                }
                
                Section(header: Text("Details")) {
                    Stepper("Available Seats: \(seats)", value: $seats, in: 1...4)
                    
                    HStack {
                        Text("₹")
                        TextField("Price per seat", text: formattedPrice)
                            .keyboardType(.numberPad)
                    }
                }
                
                Section(header: Text("Additional Information")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Section {
                    Button(action: {
                        showingConfirmation = true
                    }) {
                        Text("Create Ride")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .disabled(fromLocation.isEmpty || toLocation.isEmpty || price.isEmpty)
                    .listRowBackground(
                        (fromLocation.isEmpty || toLocation.isEmpty || price.isEmpty) ?
                        Color.gray : Color.accentColor
                    )
                }
            }
            .navigationTitle("Offer a Ride")
            .sheet(isPresented: $showingLocationSearch) {
                LocationSearchView(
                    locations: commonLocations,
                    selectedLocation: isEditingFromLocation ? $fromLocation : $toLocation,
                    isPresented: $showingLocationSearch
                )
            }
            .alert("Confirm Ride", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Create") {
                    // Handle ride creation
                    fromLocation = ""
                    toLocation = ""
                    price = ""
                    notes = ""
                    seats = 1
                    date = Date()
                }
            } message: {
                Text("Would you like to create a ride from \(fromLocation) to \(toLocation) for ₹\(price)?")
            }
        }
    }
}

struct WeekdayPicker: View {
    @Binding var selectedDays: Set<Int>
    let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        HStack {
            ForEach(0..<7) { index in
                Button(action: {
                    if selectedDays.contains(index) {
                        selectedDays.remove(index)
                    } else {
                        selectedDays.insert(index)
                    }
                }) {
                    Text(weekdays[index])
                        .frame(width: 35, height: 35)
                        .background(
                            Circle()
                                .fill(selectedDays.contains(index) ?
                                      Color.accentColor : Color.gray.opacity(0.2))
                        )
                        .foregroundColor(selectedDays.contains(index) ?
                                       .white : .primary)
                }
            }
        }
    }
}

struct LocationSearchView: View {
    let locations: [String]
    @Binding var selectedLocation: String
    @Binding var isPresented: Bool
    @State private var searchText = ""
    
    var filteredLocations: [String] {
        if searchText.isEmpty {
            return locations
        }
        return locations.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("Search location", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                ForEach(filteredLocations, id: \.self) { location in
                    Button(action: {
                        selectedLocation = location
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                            Text(location)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Select Location")
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
        }
    }
}

// MARK: - Messages View
struct MessagesView: View {
    @State private var selectedChat: Chat?
    @State private var showingChat = false
    
    // Sample chats
    let chats = [
        Chat(participant: User(id: "1", name: "Rahul Kumar", email: "rahul@gbu.ac.in", profileImage: nil),
             lastMessage: Message(sender: User(id: "1", name: "Rahul Kumar", email: "rahul@gbu.ac.in", profileImage: nil),
                                content: "I'll be at the pickup point in 5 minutes",
                                timestamp: Date().addingTimeInterval(-120),
                                isRead: false,
                                ride: nil),
             unreadCount: 1),
        Chat(participant: User(id: "2", name: "Priya Singh", email: "priya@gbu.ac.in", profileImage: nil),
             lastMessage: Message(sender: User(id: "2", name: "Priya Singh", email: "priya@gbu.ac.in", profileImage: nil),
                                content: "Thanks for the ride!",
                                timestamp: Date().addingTimeInterval(-3600),
                                isRead: true,
                                ride: nil),
             unreadCount: 0)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                if chats.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No messages yet")
                            .font(.headline)
                        Text("Your conversations will appear here")
                            .foregroundColor(.gray)
                    }
                } else {
                    List {
                        ForEach(chats) { chat in
                            ChatRow(chat: chat)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedChat = chat
                                    showingChat = true
                                }
                        }
                    }
                }
            }
            .navigationTitle("Messages")
            .sheet(isPresented: $showingChat) {
                if let chat = selectedChat {
                    ChatView(chat: chat)
                }
            }
        }
    }
}

struct ChatRow: View {
    let chat: Chat
    
    var body: some View {
        HStack {
            // Profile Image
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Text(chat.participant.name.prefix(1))
                    .font(.title2)
                    .foregroundColor(.accentColor)
            }
            
            // Message Info
            VStack(alignment: .leading, spacing: 5) {
                Text(chat.participant.name)
                    .font(.headline)
                Text(chat.lastMessage.content)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Time and Unread Count
            VStack(alignment: .trailing, spacing: 5) {
                Text(formatMessageTime(chat.lastMessage.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if chat.unreadCount > 0 {
                    Text("\(chat.unreadCount)")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.accentColor)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatMessageTime(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yy"
            return formatter.string(from: date)
        }
    }
}

struct ChatView: View {
    let chat: Chat
    @Environment(\.dismiss) var dismiss
    @State private var messageText = ""
    @State private var messages: [Message] = []
    
    var body: some View {
        NavigationView {
            VStack {
                // Messages List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message, isFromCurrentUser: message.sender.id != chat.participant.id)
                        }
                    }
                    .padding()
                }
                
                // Message Input
                HStack {
                    TextField("Type a message...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(messageText.isEmpty ? Color.gray : Color.accentColor)
                            .clipShape(Circle())
                    }
                    .disabled(messageText.isEmpty)
                    .padding(.trailing)
                }
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
            }
            .navigationTitle(chat.participant.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .onAppear {
                // Load sample messages
                messages = [
                    Message(sender: chat.participant,
                           content: "Hi! I'm interested in sharing the ride.",
                           timestamp: Date().addingTimeInterval(-3600),
                           isRead: true,
                           ride: nil),
                    Message(sender: User(id: "current", name: "Me", email: "", profileImage: nil),
                           content: "Sure! I'll be leaving from GBU at 3 PM.",
                           timestamp: Date().addingTimeInterval(-3500),
                           isRead: true,
                           ride: nil),
                    Message(sender: chat.participant,
                           content: "Perfect! I'll be at the pickup point in 5 minutes.",
                           timestamp: Date().addingTimeInterval(-120),
                           isRead: false,
                           ride: nil)
                ]
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let newMessage = Message(
            sender: User(id: "current", name: "Me", email: "", profileImage: nil),
            content: messageText,
            timestamp: Date(),
            isRead: false,
            ride: nil
        )
        
        messages.append(newMessage)
        messageText = ""
    }
}

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(10)
                    .background(isFromCurrentUser ? Color.accentColor : Color.gray.opacity(0.2))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .cornerRadius(15)
                
                Text(formatMessageTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if !isFromCurrentUser { Spacer() }
        }
    }
    
    private func formatMessageTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isEditingProfile = false
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Profile Header
                VStack(spacing: 20) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.accentColor)
                    
                    VStack(spacing: 5) {
                        Text(authManager.currentUser?.name ?? "User")
                            .font(.title2)
                            .bold()
                        Text(authManager.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 30) {
                        VStack {
                            Text("4.8")
                                .font(.headline)
                            Text("Rating")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        VStack {
                            Text("23")
                                .font(.headline)
                            Text("Rides")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        VStack {
                            Text("15")
                                .font(.headline)
                            Text("Reviews")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .listRowInsets(EdgeInsets())
                
                Section(header: Text("Vehicle Information")) {
                    ProfileRow(icon: "car.fill", text: "Toyota Camry")
                    ProfileRow(icon: "number.circle.fill", text: "ABC 123")
                    ProfileRow(icon: "paintpalette.fill", text: "Silver")
                }
                
                Section(header: Text("Account")) {
                    ProfileRow(icon: "bell.fill", text: "Notifications")
                    ProfileRow(icon: "lock.fill", text: "Privacy")
                    ProfileRow(icon: "questionmark.circle.fill", text: "Help & Support")
                }
                
                Section {
                    Button(action: {
                        showingSignOutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarItems(trailing: Button("Edit") {
                isEditingProfile.toggle()
            })
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

struct ProfileRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            Text(text)
        }
    }
}

// MARK: - Supporting Views
struct LocationAnnotationView: View {
    let location: Location
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: iconForLocationType(location.type))
                .foregroundColor(colorForLocationType(location.type))
                .background(Circle().fill(.white))
                .imageScale(.large)
            
            if location.type == .university {
                Text(location.name)
                    .font(.caption2)
                    .padding(4)
                    .background(.white.opacity(0.9))
                    .cornerRadius(4)
            }
        }
    }
    
    private func iconForLocationType(_ type: LocationType) -> String {
        switch type {
        case .university: return "building.columns.fill"
        case .metro: return "train.side.front.car"
        case .landmark: return "mappin.circle.fill"
        case .market: return "cart.fill"
        }
    }
    
    private func colorForLocationType(_ type: LocationType) -> Color {
        switch type {
        case .university: return .blue
        case .metro: return .purple
        case .landmark: return .red
        case .market: return .green
        }
    }
}

struct LocationSuggestionRow: View {
    let location: Location
    
    var body: some View {
        HStack {
            Image(systemName: iconForLocationType(location.type))
                .foregroundColor(colorForLocationType(location.type))
            Text(location.name)
                .foregroundColor(.primary)
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(10)
    }
    
    private func iconForLocationType(_ type: LocationType) -> String {
        switch type {
        case .university: return "building.columns.fill"
        case .metro: return "train.side.front.car"
        case .landmark: return "mappin.circle.fill"
        case .market: return "cart.fill"
        }
    }
    
    private func colorForLocationType(_ type: LocationType) -> Color {
        switch type {
        case .university: return .blue
        case .metro: return .purple
        case .landmark: return .red
        case .market: return .green
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption)
                    .bold()
            }
            .foregroundColor(.primary)
            .frame(width: 80)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
    }
}

struct LocationRow: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(color)
                .font(.system(size: 20))
            Text(text)
                .font(.subheadline)
                .lineLimit(1)
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
} 