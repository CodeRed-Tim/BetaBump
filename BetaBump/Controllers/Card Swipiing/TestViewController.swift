//
//  TestViewController.swift
//  BetaBump
//
//  Created by Timmy Van Cauwenberge on 2/23/21.
//

import UIKit
import Shuffle_iOS
import UIKit
import Spartan

class TestViewController: UIViewController, ButtonStackViewDelegate, SwipeCardStackDataSource, SwipeCardStackDelegate {
    
    //MARK: - Vars
    
    private let cardStack = SwipeCardStack()
    
    private let buttonStackView = ButtonStackView()
    
    let imageView = UIImageView()
    
    private let api = APIClient(configuration: .default)
    let player = AudioPlayer.shared.player
    var search: SearchTracks!
    var searchType: SpotifyType!
    
    var cardModels: [CardModel] = []

    //MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        getTracks()
        
        cardStack.delegate = self
        cardStack.dataSource = self
        buttonStackView.delegate = self
        
        fetchAndConfigureSearch()
        
        configureNavigationBar()
        layoutButtonStackView()
        layoutCardStackView()
        configureBackgroundGradient()
    }
    
    //MARK: - Configuration
    
    private func configureNavigationBar() {
        let backButton = UIBarButtonItem(title: "Back",
                                         style: .plain,
                                         target: self,
                                         action: #selector(handleShift))
        backButton.tag = 1
        backButton.tintColor = .lightGray
        navigationItem.leftBarButtonItem = backButton
        
        let forwardButton = UIBarButtonItem(title: "Forward",
                                            style: .plain,
                                            target: self,
                                            action: #selector(handleShift))
        forwardButton.tag = 2
        forwardButton.tintColor = .lightGray
        navigationItem.rightBarButtonItem = forwardButton
        
        navigationController?.navigationBar.layer.zPosition = -1
    }
    
    private func configureBackgroundGradient() {
        let backgroundGray = UIColor(red: 244 / 255, green: 247 / 255, blue: 250 / 255, alpha: 1)
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.white.cgColor, backgroundGray.cgColor]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    //MARK: - Button Stack View
    
    private func layoutButtonStackView() {
        view.addSubview(buttonStackView)
        buttonStackView.anchor(left: view.safeAreaLayoutGuide.leftAnchor,
                               bottom: view.safeAreaLayoutGuide.bottomAnchor,
                               right: view.safeAreaLayoutGuide.rightAnchor,
                               paddingLeft: 24,
                               paddingBottom: 12,
                               paddingRight: 24)
    }
    
    private func layoutCardStackView() {
        view.addSubview(cardStack)
        cardStack.anchor(top: view.safeAreaLayoutGuide.topAnchor,
                         left: view.safeAreaLayoutGuide.leftAnchor,
                         bottom: buttonStackView.topAnchor,
                         right: view.safeAreaLayoutGuide.rightAnchor)
    }
    
    //MARK: - Actions
    
    @objc
    private func handleShift(_ sender: UIButton) {
        cardStack.shift(withDistance: sender.tag == 1 ? -1 : 1, animated: true)
    }
    
    //MARK: API Request
    
    func fetchAndConfigureSearch() {
        
        let randomOffset = Int.random(in: 0..<1000)
        
        let token = (UserDefaults.standard.string(forKey: "token"))
        
        api.call(request: .search(token: token!, q: getRandomSearch(), type: .track, market: "US", limit: 1, offset: randomOffset) { [self] result in
            
            let tracks = result as? Result<SearchTracks, Error>
            
            switch tracks {
            
            case .success(let something):
                
                let oldModelsCount = self.cardModels.count
                
                for track in something.tracks.items {
                    
                    let newTrack = SimpleTrack(artistName: track.album.artists.first?.name,
                                               id: track.id,
                                               title: track.name,
                                               previewURL: track.previewUrl,
                                               images: track.album.images!,
                                               albumName: track.album.name)
                    
                    let coverImageURL = newTrack.images[0].url
                    print(coverImageURL)
                    self.imageView.kf.setImage(with: coverImageURL)

                    imageView.contentMode = .scaleAspectFill
                    
                    let songModel = CardModel(songName: newTrack.title, artistName: newTrack.artistName, imageView: imageView)
                    self.cardModels.append(songModel)
                    
                    let currentPlayingId = UserDefaults.standard.string(forKey: "current_playing_id")
                    
                    
                    
                    print("PREVIEW TRACK IS.... ", newTrack.previewUrl)
                    
                    let previewURL = newTrack.previewUrl
                    
                    DispatchQueue.main.async {
                        if previewURL == nil {
                            player?.stop()
                        } else {
                            AudioPlayer.shared.downloadFileFromURL(url: previewURL!)
                        }
                    }
                }
                
                let newModelsCount = self.cardModels.count
                let newIndices = Array(oldModelsCount..<newModelsCount)
                
                DispatchQueue.main.async {
                    self.cardStack.appendCards(atIndices: newIndices)
                }
                
            case .failure(let error):
                print("search query failed bc... ", error)
            case .none:
                print("not decoding correctly")
            }
        })
        
        
    }
    
    //MARK: Helpers
    
    func getRandomLetter(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
    
    func getRandomSearch() -> String {
        let randomChar = getRandomLetter(length: 1)
        var randomSearch = ""
        
        // Places the wildcard character at the beginning, or both beginning and end, randomly.
        randomSearch = randomChar + "%"
        
        print("random search = ", randomSearch)
        
        return randomSearch
    }
    
    //MARK: - Shuffle Functions
    
    func cardStack(_ cardStack: SwipeCardStack, cardForIndexAt index: Int) -> SwipeCard {
        let card = SwipeCard()
        card.content?.widthAnchor
        card.footerHeight = 100
        card.swipeDirections = [.left, .up, .right]
        for direction in card.swipeDirections {
            card.setOverlay(CardOverlay(direction: direction), forDirection: direction)
        }
        
        let model = cardModels[index]
        card.content = CardContentView(withImageView: model.imageView)
        card.footer = CardFooterView(withTitle: "\(model.songName)", subtitle: model.artistName)
        
        return card
    }
    
    func numberOfCards(in cardStack: SwipeCardStack) -> Int {
        print("numberOfCards...", cardModels.count)
        return cardModels.count
    }
    
    func didSwipeAllCards(_ cardStack: SwipeCardStack) {
        fetchAndConfigureSearch()
        print("Swiped all cards!")
    }
    
    func cardStack(_ cardStack: SwipeCardStack, didUndoCardAt index: Int, from direction: SwipeDirection) {
        print("Undo \(direction) swipe on \(cardModels[index].songName)")
    }
    
    func cardStack(_ cardStack: SwipeCardStack, didSwipeCardAt index: Int, with direction: SwipeDirection) {
        print("Swiped \(direction) on \(cardModels[index].songName)")
    }
    
    func cardStack(_ cardStack: SwipeCardStack, didSelectCardAt index: Int) {
        print("Card tapped")
    }
    
    func didTapButton(button: Button) {
        switch button.tag {
        case 1:
            cardStack.undoLastSwipe(animated: true)
        case 2:
            cardStack.swipe(.left, animated: true)
        case 3:
            cardStack.swipe(.up, animated: true)
        case 4:
            cardStack.swipe(.right, animated: true)
            player?.pause()
        case 5:
            cardStack.reloadData()
        default:
            break
        }
    }
}

//MARK: - Extensions

extension UIWindow {
    static var key: UIWindow? {
        if #available(iOS 13, *) {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}
