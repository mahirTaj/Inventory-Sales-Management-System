```markdown
# 📦 Inventory & Sales Management System

A simple inventory and sales management system with core features like adding products, updating stock, processing sales, generating reports, and undoing transactions.

---

## 🚀 Features

### 🔹 Product Management
- Add new products with **ID, Name, Price, and Quantity**  
- Update existing product details (**price and quantity**)  
- Delete products from the inventory array  

### 🔹 Sales & Logging
- Process sales by reducing quantity  
- Maintain a **sales log** with product ID, quantity sold, and date/time  

### 🔹 Search & Sort
- Search products by **ID or Name**  
- Sort products by **Price or Quantity** using **Bubble Sort**  

### 🔹 Reports & Alerts
- **Sales Report**: total sales, best-selling products, sales count  
- **Inventory Report**: all products with current stock and prices  
- **Low Stock Alert**: automatic alerts when stock is below threshold  

### 🔹 Restock & Reorder
- Identify low-stock products for restocking  
- Add new stock to replenish inventory  

### 🔹 Undo Transactions
- Undo the **last sale transaction**  
- Confirmation prompt before undo  
- Support for **multiple undos with limits**  
- Automatically updates reports and alerts  

---

## 📊 Example Workflows

1. **Add Product** → Enter ID, Name, Price, Quantity  
2. **Sell Product** → Quantity decreases, sale logged  
3. **View Reports** → Check total sales and stock levels  
4. **Undo Sale** → Restore previous stock & update logs  

---

## 🛠️ Tech Stack
- Language: **C / C++** (array-based implementation)  
- Sorting: **Bubble Sort**  
- Data: **Arrays for inventory and sales logs**  

---

## 📌 Future Enhancements
- File-based persistence (save/load inventory)  
- GUI integration  
- Advanced sorting/searching (Quick Sort, Binary Search)  

---

## 📖 License
This project is open-source and available under the [MIT License](LICENSE).  
```
