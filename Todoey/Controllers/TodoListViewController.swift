
import UIKit
import CoreData

class TodoListViewController: UITableViewController {
    
    var selectedCategory: Category? {
        
        didSet{ //this happens as soon as the selectedCategory variable is set, which happens in categoryViewController when we select a cell, it's a better place to reload the data that viewDidLoad
            loadItems()
        }
    }
    
    var itemArray = [Item]()
//    = [Item("aa"), Item("bb"), Item("cc")]
   // let defaults = UserDefaults.standard
    
    let dataFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Items.plist") //nscoder

    
   // print(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last! as String) //prints the path for the directories where data of the project is saved (sand box)
    //we print it in application did finish launch

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    // (UIApplication.shared.delegate as! AppDelegate) is just a singlton to get hold of an object of the ui app delegate running right now so we can use an instance of it which is persistentContainer.viewContext which is our core data base file
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = selectedCategory!.name
        view.backgroundColor = .systemBackground
        addButton()
      //  view.backgroundColor = .systemBlue //whole view is blue
    //    loadItems()
    //    print(dataFilePath)
        
//
//        if let items = defaults.array(forKey: "TodoListArray") as? [String]{ //type[Any] has to be downcasted to [String], it returns an optional so we option bind it
//            //instead of itemArray = defaults.array(forKey: "TodoListArray") as! [String]
//            itemArray = items
//        }
        
    }
    
    //MARK - TableView DataSource Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArray.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoItemCell", for: indexPath)
        let item = itemArray[indexPath.row]
        cell.textLabel?.text = item.title
        cell.accessoryType = item.done ? .checkmark : .none //ternary operrator returns a value from the if condition
        return cell
    }
    
    //MARK - TableView Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //two ways are valid to save the updates
        //1
//        itemArray[indexPath.row].title = "hi"
        itemArray[indexPath.row].done.toggle()
        //2
//        var done = itemArray[indexPath.row].done ? false : true
//        itemArray[indexPath.row].setValue(done, forKey: "done")
        
       
        
        saveItems()
//        if tableView.cellForRow(at: indexPath)?.accessoryType == .checkmark {
//            tableView.cellForRow(at: indexPath)?.accessoryType = .none
//        } else {
//            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
//        }
        tableView.deselectRow(at: indexPath, animated: true)

    }
    
    //MARK - deleting Items

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {//trailing is when you swap to the left, there is leading function to swap to the right
       
        let deleteAction = UIContextualAction(style: .destructive, title: "delete"){//.destructive make the background color red
            (action,view,completionHandler) in
            //order matters, you have to delete it first from the data base and save it then from the array because we're using the array indexpath to access the table in the database
            self.context.delete(self.itemArray[indexPath.row])
            self.saveItems()
            self.itemArray.remove(at: indexPath.row)
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            
            completionHandler(true) //means i finished editing in this function (deletAction), deleted in the arr and the tableview
        }
      
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    //MARK - Add New Items
    private func addButton(){ //if the nvigation controller is in the root
        navigationItem.rightBarButtonItem = UIBarButtonItem( barButtonSystemItem: .add, target: self, action: #selector(addNewItem))
    }
    @objc func addNewItem(){
        var textfield = UITextField()
        
        let alert = UIAlertController(title: "Add New Todey Item", message: "", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            //what will happen once the user clicks the add item button on uialert
           
            //self.itemArray.append(Item(textfield.text!)) //nscoder using the item class
          //  self.defaults.set(self.itemArray, forKey: "TodoListArray")
//            we use the item entity in our data model class to create new opjects to be saved in the core data, item class file which we used in nscoder can be deleted
            let newItem = Item(context: self.context)
            newItem.title = textfield.text!
            newItem.done = false
            newItem.parentCategory = self.selectedCategory //parentcategory variable is created in the data model
            self.itemArray.append(newItem)
            
            self.saveItems()
        }
        alert.addTextField{ (alertTextField) in
            alertTextField.placeholder = "create new item"
            textfield = alertTextField
            
        }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
//    func saveItems(){ //nscoder
//        let encoder = PropertyListEncoder() //NSencoder
//        do{
//            let data = try encoder.encode(itemArray)
//            try data.write(to: dataFilePath!)
//        } catch {
//            print("Error encoding item array, \(error)") //encode function throws an error
//        }
//        self.tableView.reloadData()
//    }
    
    func saveItems(){ //must be called after creating, updating or deleting any items
        
        do{
            try context.save()
        } catch {
            print("Error saving context \(error)")
        }
        self.tableView.reloadData()
    }
    
    func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), predicate: NSPredicate? = nil){
        
        let CategoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", selectedCategory!.name!)
       // request.predicate = predicate //this will be overriden by any other predicate set later
        if let additionalPredicate = predicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [CategoryPredicate, additionalPredicate])
        } else {
            request.predicate = CategoryPredicate
        }
        
        do{
            itemArray = try context.fetch(request)
        } catch {
            print("Error fetching data from context \(error)")
        }
        tableView.reloadData()
    }
    
//    func loadItems(){ //nscoder
//        if let data = try? Data(contentsOf: dataFilePath!){
//            let decoder = PropertyListDecoder()
//            do{
//                itemArray = try decoder.decode([Item].self, from: data)
//            } catch {
//                print("Error decoding item array \(error)")
//            }
//        }
//    }
}

//MARK: - Search Bar methods
//quering data aka manipulating the data base
extension TodoListViewController: UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let request : NSFetchRequest<Item> = Item.fetchRequest()
        //we use nspredicate to filter the table to get the titles containing searchbar.text
        //[cd] means not case sensitive nor those french marks à á, removing the [cd] means the search is case sensiteve
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)
        //sortDescriptors takes an array of discriptors, this can be [NSSortDescriptor(key: "title", ascending: true), NSSortDescriptor(...)]
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        loadItems(with: request, predicate: predicate)
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0{ //it returns to the original list if the text field did change and the count returned to zero meaning the search button is pressed or the x button
            loadItems()
            
            DispatchQueue.main.async {//the curser and the keyboard disappears
                searchBar.resignFirstResponder()
            }
        }
    }
}
