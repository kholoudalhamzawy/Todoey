
import UIKit
import CoreData

class CategoryViewController: UITableViewController {
    
    var categories = [Category]()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext //singleton

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Todoey"
        addButton()
//        view.backgroundColor = .systemBlue //whole view is blue
        view.backgroundColor = .systemBackground

        loadItems()
       
    }

    // MARK: - Table view datasource methods


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return categories.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)

            let category = categories[indexPath.row]
        cell.textLabel?.text = category.name
        cell.accessoryType =  .disclosureIndicator
        
       return cell
    }
    
    //MARK - Table view Delegate methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        performSegue(withIdentifier: "goToItems", sender: self)
       
     //   tableView.deselectRow(at: indexPath, animated: true)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {//the prepare is performed right before the performSegue method
        
        //if we have more than one segue we should check with an if statement if segue with identifier "goToItems" to downCast it to TodoListViewController
        let destinitionVC = segue.destination as! TodoListViewController
        
        if let indexPath = tableView.indexPathForSelectedRow{//indexPathForSelectedRow is an optional to represent the selected cell as we cant get to the cell in this delegate method
            destinitionVC.selectedCategory = categories[indexPath.row] 
        }
    }
    
    //MARK - deleting Items

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {//trailing is when you swap to the left, there is leading function to swap to the right
       
        let deleteAction = UIContextualAction(style: .destructive, title: "delete"){//.destructive make the background color red
            (action,view,completionHandler) in
            //order matters, you have to delete it first from the data base and save it then from the array because we're using the array indexpath to access the table in the database
            self.context.delete(self.categories[indexPath.row])
            self.saveItems()
            self.categories.remove(at: indexPath.row)
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
            
            let newCategory = Category(context: self.context)
            newCategory.name = textfield.text!
            self.categories.append(newCategory)
            
            self.saveItems()
        }
        alert.addTextField{ (alertTextField) in
            alertTextField.placeholder = "create new item"
            textfield = alertTextField
            
        }
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    func saveItems(){ //must be called after creating, updating or deleting any items
        
        do{
            try context.save()
        } catch {
            print("Error saving context \(error)")
        }
        self.tableView.reloadData()
    }
    
    func loadItems(with request: NSFetchRequest<Category> = Category.fetchRequest()){
        do{
            categories = try context.fetch(request)
        } catch {
            print("Error fetching data from context \(error)")
        }
        tableView.reloadData()
    }

    
}
