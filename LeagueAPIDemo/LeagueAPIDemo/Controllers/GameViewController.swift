//
//  GameViewController.swift
//  LeagueAPIDemo
//
//  Created by Antoine Clop on 12/17/18.
//  Copyright © 2018 Antoine Clop. All rights reserved.
//

import UIKit
import LeagueAPI

class GameViewController: UIViewController {
    
    // MARK: - IBOulet
    
    @IBOutlet weak var gameTableView: UITableView!
    
    // MARK: - Variables
    
    public var game: GameInfo?
    private var blueTeam: [Participant] = []
    private var redTeam: [Participant] = []
    private var blueBans: [BannedChampion] = []
    private var redBans: [BannedChampion] = []
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fillTeams()
        self.fillBans()
    }
    
    // MARK: - Setup
    
    func fillTeams() {
        guard let game = self.game else { return }
        let blueTeamId: Long = 100
        for participant in game.participants {
            if participant.teamId == blueTeamId {
                self.blueTeam.append(participant)
            }
            else {
                self.redTeam.append(participant)
            }
        }
    }
    
    func fillBans() {
        guard let game = self.game else { return }
        let blueTeamId: Long = 100
        for bannedChampion in game.bannedChampions {
            if bannedChampion.teamId == blueTeamId {
                self.blueBans.append(bannedChampion)
            }
            else {
                self.redBans.append(bannedChampion)
            }
        }
    }
    
    // MARK: - Functions
    
    func participant(at indexPath: IndexPath) -> Participant {
        let teamAtIndexPath: [Participant] = indexPath.section == 1 ? self.blueTeam : self.redTeam
        return teamAtIndexPath[indexPath.row]
    }
    
    func getChampionImage(championId: ChampionId, completion: @escaping (UIImage?) -> Void) {
        league.getChampionDetails(by: championId) { (champion, errorMsg) in
            if let champion = champion, let defaultSkin = champion.images?.square {
                defaultSkin.getImage() { (image, error) in
                    completion(image)
                }
            }
            else {
                print("Request failed cause: \(errorMsg ?? "No error description")")
            }
        }
    }
    
    func getSummonerImage(profileIconId: ProfileIconId, completion: @escaping (UIImage?) -> Void) {
        league.getProfileIcon(by: profileIconId) { (profileIcon, errorMsg) in
            if let profileIcon = profileIcon {
                profileIcon.profileIcon.getImage() { (image, error) in
                    completion(image)
                }
            }
            else {
                print("Request failed cause: \(errorMsg ?? "No error description")")
            }
        }
    }
    
    func getChampionMastery(summonerId: SummonerId, championId: ChampionId, completion: @escaping (Int?) -> Void) {
        league.riotAPI.getChampionMastery(by: summonerId, for: championId, on: preferedRegion) { (championMastery, errorMsg) in
            if let championMastery = championMastery {
                completion(championMastery.championLevel)
            }
            else {
                print("Request failed cause: \(errorMsg ?? "No error description")")
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
}

extension GameViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return self.blueTeam.count
        case 2:
            return self.redTeam.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Banned Champions"
        case 1:
            return "Blue Team"
        case 2:
            return "Red Team"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return setupBanCell(for: indexPath.row == 0)
        }
        else {
            let participantAtIndex: Participant = self.participant(at: indexPath)
            return setupParticipantCell(for: participantAtIndex)
        }
    }
    
    func setupBanCell(for blueTeam: Bool) -> BanTableViewCell {
        let newCell: BanTableViewCell = self.gameTableView.dequeueReusableCell(withIdentifier: "banCell") as! BanTableViewCell
        newCell.isUserInteractionEnabled = false
        let teamBans: [BannedChampion] = blueTeam ? self.blueBans : self.redBans
        for (index, ban) in teamBans.enumerated() {
            let ban: BannedChampion = teamBans[index]
            self.getChampionImage(championId: ban.championId) { image in
                var imageView: UIImageView {
                    switch index {
                    case 0:
                        return newCell.banChampionSquare1
                    case 1:
                        return newCell.banChampionSquare2
                    case 2:
                        return newCell.banChampionSquare3
                    case 3:
                        return newCell.banChampionSquare4
                    default:
                        return newCell.banChampionSquare5
                    }
                }
                imageView.setImage(image)
            }
        }
        if blueTeam {
            newCell.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        }
        else {
            newCell.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        }
        return newCell
    }
    
    func setupParticipantCell(for participant: Participant) -> PlayerTableViewCell {
        let newCell: PlayerTableViewCell = self.gameTableView.dequeueReusableCell(withIdentifier: "playerCell") as! PlayerTableViewCell
        self.getChampionImage(championId: participant.championId) { image in
            newCell.championSquare.setImage(image)
        }
        self.getSummonerImage(profileIconId: participant.profileIconId) { image in
            newCell.summonerSquare.setImage(image)
        }
        // Missing rank icon
        newCell.summonerName.text = participant.summonerName
        if let summonerId = participant.summonerId {
            self.getChampionMastery(summonerId: summonerId, championId: participant.championId) { masteryLevel in
                newCell.masteryLabel.text = "\(masteryLevel ?? 0)"
            }
        }
        return newCell
    }
}

extension GameViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section > 0 else { return }
        let participantAtIndex: Participant = self.participant(at: indexPath)
        self.performSegue(withIdentifier: "showParticipant", sender: participantAtIndex)
    }
}
