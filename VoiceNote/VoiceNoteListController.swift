//
//  VoiceNoteListController.swift
//  VoiceNote
//
//  Created by darrenyao on 2016/11/18.
//  Copyright © 2016年 VoiceNote. All rights reserved.
//

import UIKit
import AVFoundation
import MagicalRecord

class VoiceNoteListController: UITableViewController {
    //Constant
    struct Cell {
        struct Identifier {
            static let VoiceNote = "VoiceNoteCell"
        }
    }
    
    //MARK: Property
    var fetchedResultsController : NSFetchedResultsController<VoiceNoteData>!
    var voiceCellVMs : [VoiceNoteCellVM] =  [VoiceNoteCellVM]()
    var selectedVoiceCellVM : VoiceNoteCellVM? {
        didSet {
            oldValue?.state = VoiceState.pause
            changePlayState(newVoice: selectedVoiceCellVM, oldVoice: oldValue)
        }
    }
    var audioPlayer : AVAudioPlayer?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = 80
        
        fetchedResultsController = VoiceNoteData.mr_fetchAllSorted(by: "date", ascending: false, with: nil, groupBy: nil, delegate: self, in:NSManagedObjectContext.mr_default()) as! NSFetchedResultsController<VoiceNoteData>
        let voices = fetchedResultsController.fetchedObjects ?? [VoiceNoteData]()
        for voice in voices {
            voiceCellVMs.append(VoiceNoteCellVM(data: voice))
        }
    }
    
    func changePlayState(newVoice: VoiceNoteCellVM?, oldVoice: VoiceNoteCellVM?) {
        //点击同一个Voice
        if  newVoice == oldVoice {
            newVoice?.changeState()
            return
        }
        
        //点击不同Voice，先释放前一个AVAudioPlayer
        audioPlayer?.delegate = nil
        audioPlayer?.pause()
        audioPlayer = nil
        
        //点击新的Voice
        guard let newVoice = newVoice else {
            return
        }
        
        let path = newVoice.audioPath()
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            audioPlayer?.delegate = self
            audioPlayer?.isMeteringEnabled = true
            
            newVoice.state = VoiceState.play
        } catch let error as NSError {
            debugPrint("\(error.localizedDescription)")
            return
        }
        
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension VoiceNoteListController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return voiceCellVMs.count > 0 ? 1 : 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return voiceCellVMs.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.Identifier.VoiceNote) as! VoiceNoteCell
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let voiceVM = voiceCellVMs[indexPath.row]
        
        if let cell = cell as? VoiceNoteCell {
            cell.viewModel = voiceVM
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! VoiceNoteCell
        self.selectedVoiceCellVM = cell.viewModel
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension VoiceNoteListController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            let voice = self.fetchedResultsController.object(at: newIndexPath!)
            voiceCellVMs.insert(VoiceNoteCellVM(data: voice), at: newIndexPath!.row)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            voiceCellVMs.remove(at: indexPath!.row)
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .update:
            break
//            let cell = tableView.cellForRow(at: indexPath!) as! VoiceNoteCell
//            let voice = fetchedResultsController.object(at: indexPath!)
//            let voiceVM = VoiceNoteCellVM(data: voice)
//            cell.viewModel = voiceVM
        case .move:
            voiceCellVMs.remove(at: indexPath!.row)
            tableView.deleteRows(at: [indexPath!], with: .automatic)
            
            let voice = self.fetchedResultsController.object(at: newIndexPath!)
            voiceCellVMs.insert(VoiceNoteCellVM(data: voice), at: newIndexPath!.row)
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        }
        
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
}

extension VoiceNoteListController : AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            selectedVoiceCellVM?.state = VoiceState.pause
            selectedVoiceCellVM?.progress = 0
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        debugPrint(error?.localizedDescription ?? "")
    }
}

