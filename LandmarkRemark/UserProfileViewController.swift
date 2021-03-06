//
//  UserProfileViewController.swift
//  LandmarkRemark
//
//  Created by Gagandeep Singh on 22/6/16.
//  Copyright © 2016 Gagandeep Singh. All rights reserved.
//

import UIKit
import Parse

class UserProfileViewController: UIViewController, UserProfileViewModelDelegate {
    
    //MARK:- OURTETS
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var notesCount: UILabel!
    @IBOutlet weak var notesLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    
    //MARK:- VARIABLES
    
    var viewModel: UserProfileVewModel!
    
    var refreshControl: UIRefreshControl!
    var notes: [NoteObject]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = UserProfileVewModel(delegate: self)

        //Set table view delegate and data source
        tableView.delegate   = self
        tableView.dataSource = self
        
        //Add refresh control to table view
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(fetchUserNotes), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        fetchUserNotes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Set Self as Active View Controller
        ActiveViewController = self
        
        //Populize String
        self.logoutButton.setTitle(NSLocalizedString("LOG_OUT", comment: "Log Out"), for: UIControlState.application)
        self.notesLabel.text = NSLocalizedString("NOTES", comment: "Notes").lowercased()
        
        //Populize Labels
        populizeLabels()
    }
    
    func populizeLabels() {
        
        self.usernameLabel.text = CurrentUser!.username
        self.notesCount.text = "\(CurrentUser!.notesCount!)"
    }
    
    
    //MARK:- FETCH NOTES
    func fetchUserNotes() {
        
        //Initialize notes array
        viewModel.fetchNotes(forUser: CurrentUser!) { (notes, error) in
            if let notes = notes {
                
                self.notes = notes
                self.tableView.reloadData()
            }
            
            self.refreshControl.endRefreshing()
        }
    }
    
    @IBAction func logout() {
        
        let title = NSLocalizedString("ARE_YOU_SURE", comment: "Location access title")
        
        let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)
        
        let cancelAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("CANCEL", comment: "Cancel"), style: .cancel, handler: nil)
        let logoutAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("LOG_OUT", comment: "Log Out"), style: .destructive) { (action) in
            
            //Log Out Parse User
            self.viewModel.logOut(completion: { (error) in
                if error == nil {
                    
                    //Make Home View active
                    self.tabBarController?.selectedIndex = 0
                    
                    //Go to log in screen
                    RootVC.popToRootViewController(animated: true)
                } else {
                    
                    showMessageView(message: "Log Out Failed", valid: false, completion: nil)
                }
            })
        }
        
        alert.addAction(cancelAction)
        alert.addAction(logoutAction)
        
        self.present(alert, animated: true, completion: nil)
    }

}


//--------------------------------------------------------------------------------
//MARK:- UITalbleView Delegate
//--------------------------------------------------------------------------------
extension UserProfileViewController:  UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes == nil ? 0 : notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let note = notes[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "noteDetailsCell") as! NoteDetailsCell
        
        cell.noteDetailsView.delegate = self
        cell.initialize(withNoteObject: note, atIndexPath: indexPath)
        
        return cell
    }
    
    //MARK:- TABLE VIEW DELEGATE
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //Calculate height for cell accroding to contents of Note
        let note = notes[indexPath.row]
        let height = calculateNoteHeight(note: note)
        
        
        //Compensate for other objects in table cell
        return height + 180
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        tableView.backgroundColor = UIColor.clear()
        tableView.backgroundView?.backgroundColor = UIColor.clear()
        cell.backgroundColor = UIColor.clear()
        cell.contentView.backgroundColor = UIColor.clear()
    }
    
    
    //Calculate note height for table view cell
    func calculateNoteHeight(note: NoteObject) -> CGFloat {
        //Initiate an option UILabel, which can be nullified later
        var tempLabel: UILabel?
        tempLabel = UILabel(frame: CGRect(x: 10, y: 0, width: ScreenSize.width - 60, height: CGFloat.greatestFiniteMagnitude))
        tempLabel!.numberOfLines = 0
        tempLabel!.font = UIFont.systemFont(ofSize: 18)
        tempLabel!.text = note.note
        tempLabel!.sizeToFit()
        
        //Compensate for subtitle label
        let height = tempLabel!.frame.height + 20
        tempLabel = nil
        
        return height
    }
    
}


//--------------------------------------------------------------------------------
//MARK:- NoteDetailsView Delegate
//--------------------------------------------------------------------------------
extension UserProfileViewController: NoteDetailsViewDelegate {
    
    
    //MARK: Show Note Options
    func showNoteOptions(forNote note: NoteObject) {
        
        //Create Action Sheet for Edit & Delete optiions
        let actionSheet: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let editAction = UIAlertAction(title: NSLocalizedString("EDIT", comment: "Edit"), style: .default) { (action) in
            //Edit Segue
            self.editNote(note: note)
        }
        
        let deleteAction = UIAlertAction(title: NSLocalizedString("DELETE", comment: "Delete"), style: .destructive) { (action) in
            self.deleteNote(note: note)
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("CANCEL", comment: "Cancel"), style: .cancel, handler: nil)
        
        actionSheet.addAction(editAction)
        actionSheet.addAction(deleteAction)
        actionSheet.addAction(cancelAction)
        
        //Show Action Sheet
        present(actionSheet, animated: true, completion: nil)
    }
    
    
    //MARK: Edit Note
    func editNote(note: NoteObject) {
        
        //Set Destination View Controller as Compose View Controller
        let destVc = MainStoryboard.instantiateViewController(withIdentifier: "ComposeViewController") as! ComposeViewController
        
        //Setup Compose View Controller variables
        destVc.editingNote = true
        destVc.noteToEdit = note
        destVc.locality = note.locationString
        
        //Persent Compose View Controller
        present(destVc, animated: true, completion: nil)
    }
    
    
    //MARK: Delete Note
    func deleteNote(note: NoteObject) {
        
        //Show alert to confim
        let alertView: UIAlertController = UIAlertController(title: NSLocalizedString("ARE_YOU_SURE", comment: "Are you sure?"), message: nil, preferredStyle: .alert)
        
        //Add Delete Action
        let deleteAction = UIAlertAction(title: NSLocalizedString("DELETE", comment: "Delete"), style: .destructive) { (action) in
            
            //Delete note on Database
            note.deleteNote(completion: { (success, error) in
                
                if success {
                    //If note deleted, update UI
                    self.noteDeleted(deletedNote: note)
                    
                } else {
                    //Show error message
                    showMessageView(message: NSLocalizedString("NOTE_NOT_DELETED", comment: "Note not deleted"), valid: false, completion: nil)
                }
            })
        }
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("CANCEL", comment: "Cancel"), style: .cancel, handler: nil)
        
        alertView.addAction(cancelAction)
        alertView.addAction(deleteAction)
        
        present(alertView, animated: true, completion: nil)
    }
    
    
    //MARK: Note Deleted
    func noteDeleted(deletedNote: NoteObject) {
        
        //Remove deleted note from notes array
        notes = notes.filter({ (note) -> Bool in
         
            if note.objectId == deletedNote.objectId {
                return false
            }
            return true
            
        })
        
        //Update User Notes Count
        CurrentUser!.notesCount = CurrentUser!.notesCount - 1
        CurrentUser!.updateParseUser()
        
        //Reload notes list
        tableView.reloadData()
        
        //Re-populize labels
        populizeLabels()
    }
}
