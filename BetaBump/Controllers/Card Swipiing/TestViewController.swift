//
//  TestViewController.swift
//  BetaBump
//
//  Created by Timmy Van Cauwenberge on 2/23/21.
//

import UIKit
import Shuffle_iOS
import SDWebImage

class TestViewController: UIViewController, ButtonStackViewDelegate, SwipeCardStackDataSource, SwipeCardStackDelegate {
    
    
    private let cardStack = SwipeCardStack()
    
    private let buttonStackView = ButtonStackView()
    
    let imageView = UIImageView()
    
    private let api = APIClient(configuration: .default)
    let player = AudioPlayer.shared.player
    var previewURL: URL? = nil
    var search: SearchTracks!
    var searchType: SpotifyType!
    
    var cardModels: [CardModel] = []
    //        CardModel(songName: "Borderline",
    //                  artistName: "Tame Impala",
    //                  image: UIImage(named: "borderline")),
    //        CardModel(songName: "Always Been You",
    //                  artistName: "Quin XCII",
    //                  image: UIImage(named: "alwaysbeenyou")),
    //        CardModel(songName: "Lost",
    //                  artistName: "Frank Ocean",
    //                  image: UIImage(named: "lost")),
    //        CardModel(songName: "Goodie Bag",
    //                  artistName: "Still Woozy",
    //                  image: UIImage(named: "goodiebag")),
    //        CardModel(songName: "Rachel",
    //                  artistName: "Interior Designer",
    //                  image: UIImage(named: "rachel"))
    //    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cardStack.delegate = self
        cardStack.dataSource = self
        buttonStackView.delegate = self
        
        fetchAndConfigureSearch()
        
//        cardModels.append(CardModel(songName: "Tim's Song", artistName: "Tim", image: UIImage(named: "rachel")))
//        cardStack.appendCards(atIndices: [cardModels.count - 1])
        
        configureNavigationBar()
        layoutButtonStackView()
        layoutCardStackView()
        configureBackgroundGradient()
    }
    
    //    override func viewDidAppear(_ animated: Bool) {
    //        addCards()
    //    }
    
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
    
    @objc
    private func handleShift(_ sender: UIButton) {
        cardStack.shift(withDistance: sender.tag == 1 ? -1 : 1, animated: true)
    }
    
    
    func fetchAndConfigureSearch() {
        
        let randomOffset = Int.random(in: 0..<1000)
        
        let token = (UserDefaults.standard.string(forKey: "token"))
        
        api.call(request: .search(token: token!, q: getRandomSearch(), type: .track, market: "US", limit: 5, offset: randomOffset) { [self] result in
            
            let tracks = result as? Result<SearchTracks, Error>
            
            switch tracks {
            
            case .success(let something):
                
                for track in something.tracks.items {
                    
                    let newTrack = SimpleTrack(artistName: track.album.artists.first?.name,
                                               id: track.id,
                                               title: track.name,
                                               previewURL: track.previewUrl,
                                               images: track.album.images!,
                                               albumName: track.album.name)
                    
                    let coverImageURL = newTrack.images[0].url
                    self.imageView.kf.setImage(with: coverImageURL)
                                        
                    let songModel = CardModel(songName: newTrack.title, artistName: newTrack.artistName, imageView: imageView)
                    cardModels.append(songModel)
                    let newIndices = Array(self.cardModels.count-1..<self.cardModels.count)
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
    
//    private func addCards() {
//
//
//
//        fetchAndConfigureSearch { [weak self] newModels in
//            guard let strongSelf = self else { return }
//
//            let oldModelsCount = strongSelf.cardModels.count
//            let newModelscount = oldModelsCount + newModels.count
//
//            DispatchQueue.main.async {
//                strongSelf.cardModels.append(contentsOf: newModels)
//
//                let newIndices = Array(oldModelsCount..<newModelscount)
//                strongSelf.cardStack.appendCards(atIndices: newIndices)
//            }
//        }
//
//        print("addCards() CARD MODELS...", cardModels)
//    }
    
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
    
    func cardStack(_ cardStack: SwipeCardStack, cardForIndexAt index: Int) -> SwipeCard {
        let card = SwipeCard()
        card.footerHeight = 80
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
        case 5:
            cardStack.reloadData()
        default:
            break
        }
    }
    
    
}

// MARK: Data Source + Delegates

//extension TestViewController: ButtonStackViewDelegate, SwipeCardStackDataSource, SwipeCardStackDelegate {
//
//    func cardStack(_ cardStack: SwipeCardStack, cardForIndexAt index: Int) -> SwipeCard {
//        let card = SwipeCard()
//        card.footerHeight = 80
//        card.swipeDirections = [.left, .up, .right]
//        for direction in card.swipeDirections {
//            card.setOverlay(CardOverlay(direction: direction), forDirection: direction)
//        }
//
//        print("Track models ...... ", trackModels)
//        print("Track Models length is...", trackModels.count)
//
//        let model = cardModels[index]
//        card.content = CardContentView(withImage: model.image)
//        card.footer = CardFooterView(withTitle: "\(model.songName)", subtitle: model.artistName)
//
//        return card
//    }
//
//    func numberOfCards(in cardStack: SwipeCardStack) -> Int {
//        print("numberOfCards...", cardModels.count)
//        return cardModels.count
//    }
//
//    func didSwipeAllCards(_ cardStack: SwipeCardStack) {
//        print("Swiped all cards!")
//    }
//
//    func cardStack(_ cardStack: SwipeCardStack, didUndoCardAt index: Int, from direction: SwipeDirection) {
//        print("Undo \(direction) swipe on \(cardModels[index].songName)")
//    }
//
//    func cardStack(_ cardStack: SwipeCardStack, didSwipeCardAt index: Int, with direction: SwipeDirection) {
//        print("Swiped \(direction) on \(cardModels[index].songName)")
//    }
//
//    func cardStack(_ cardStack: SwipeCardStack, didSelectCardAt index: Int) {
//        print("Card tapped")
//    }
//
//    func didTapButton(button: Button) {
//        switch button.tag {
//        case 1:
//            cardStack.undoLastSwipe(animated: true)
//        case 2:
//            cardStack.swipe(.left, animated: true)
//        case 3:
//            cardStack.swipe(.up, animated: true)
//        case 4:
//            cardStack.swipe(.right, animated: true)
//        case 5:
//            cardStack.reloadData()
//        default:
//            break
//        }
//    }
//}
