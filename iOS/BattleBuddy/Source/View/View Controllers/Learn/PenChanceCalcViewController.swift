//
//  PenChanceCalcViewController.swift
//  BattleBuddy
//
//  Created by Mike on 7/20/19.
//  Copyright © 2019 Veritas. All rights reserved.
//

import UIKit
import BallisticsEngine
import JGProgressHUD

class PenChanceCalcViewController: BaseCalculatorViewController {
    let dbManager = DependencyManagerImpl.shared.databaseManager()
    var calculator = PenetrationCalculator()
    let selectionCellId = "ItemSelectionCell"
    let resultLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 110.0, weight: .ultraLight)
        label.adjustsFontSizeToFitWidth = true
        label.textColor = UIColor.init(white: 0.9, alpha: 1.0)
        label.text = "-"
        return label
    }()
    let durabilityLabelStackView = BaseStackView(axis: .horizontal, spacing: 0.0, yPadding: 0.0)
    let durabilityLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 30.0, weight: .ultraLight)
        label.textColor = UIColor.init(white: 0.9, alpha: 1.0)
        label.text = Localized("armor_points")
        label.isHidden = true
        return label
    }()
    let durabilityValueLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 24.0, weight: .light)
        label.textColor = UIColor.init(white: 0.9, alpha: 1.0)
        label.isHidden = true
        return label
    }()
    let durabilitySliderStackView = BaseStackView(axis: .horizontal, spacing: 0.0, yPadding: 0.0)
    let durabilitySlider: UISlider = {
        let slider = UISlider(frame: .zero)
        slider.tintColor = UIColor.Theme.primary
        slider.enable(false)
        return slider
    }()
    lazy var selectionCollectionView: BaseCollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal

        let collectionView = BaseCollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(ItemPreviewCell.self, forCellWithReuseIdentifier: selectionCellId)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    let gunshotButtonStackView = BaseStackView(axis: .horizontal, distribution: .fillEqually)
    lazy var penButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.setTitle("simulate_gunshot_pen".local(), for: .normal)
        button.addTarget(self, action: #selector(simulateShotWithPen), for: .touchUpInside)
        button.enable(false)
        button.applyDefaultStyle()
        return button
    }()
    lazy var noPenButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.setTitle("simulate_gunshot_no_pen".local(), for: .normal)
        button.addTarget(self, action: #selector(simulateShotWithNoPen), for: .touchUpInside)
        button.enable(false)
        button.applyDefaultStyle()
        return button
    }()

    var armor: SimulationArmor? {
        didSet {
            if let armor = armor {
                durabilitySlider.enable(true)
                durabilityValueLabel.isHidden = false
                durabilityLabel.isHidden = false

                durabilitySlider.minimumValue = 0
                durabilitySlider.maximumValue = Float(armor.maxDurability)
                durabilitySlider.value = durabilitySlider.maximumValue
                updateCalculator()
            } else {
                durabilitySlider.enable(false)
                durabilityValueLabel.isHidden = true
                durabilityLabel.isHidden = true
            }
        }
    }
    var ammo: SimulationAmmo? {
        didSet {
            durabilitySlider.value = durabilitySlider.maximumValue
            updateCalculator()
        }
    }
    var ammoOptions: [SimulationAmmo]?
    var armorOptions: [SimulationArmor]?

    required init?(coder aDecoder: NSCoder) { fatalError() }

    init() {
        super.init(BaseStackView(axis: .vertical, spacing: 7.0, xPaddingCompact: 30.0, xPaddingRegular: 150.0, yPadding: 0.0))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = Localized("pen_chance")

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "help"), style: .plain, target: self, action: #selector(showHelp))

        durabilitySlider.addTarget(self, action: #selector(updateCalculator), for: .valueChanged)

        stackView.addArrangedSubview(resultLabel)
        stackView.addArrangedSubview(UIView())
        stackView.addArrangedSubview(selectionCollectionView)
        stackView.addArrangedSubview(durabilityLabelStackView)
        stackView.addArrangedSubview(durabilitySliderStackView)
        stackView.addArrangedSubview(gunshotButtonStackView)

        durabilityLabelStackView.addArrangedSubview(durabilityLabel)
        durabilityLabelStackView.addArrangedSubview(UIView())
        durabilityLabelStackView.addArrangedSubview(durabilityValueLabel)
        durabilitySliderStackView.addArrangedSubview(durabilitySlider)

        gunshotButtonStackView.addArrangedSubview(penButton)
        gunshotButtonStackView.addArrangedSubview(noPenButton)

        NSLayoutConstraint.activate([
            NSLayoutConstraint.init(item: resultLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 175.0),
            NSLayoutConstraint.init(item: selectionCollectionView, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 0.2, constant: 0.0),
            NSLayoutConstraint.init(item: durabilityLabelStackView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 30.0),
            NSLayoutConstraint.init(item: durabilitySlider, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 60.0),
            NSLayoutConstraint.init(item: penButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 55.0),
            NSLayoutConstraint.init(item: noPenButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 55.0),
        ])
    }

    @objc func showHelp() {
        presentDefaultAlert(title: "pen_chance_help_title".local(), message: "pen_chance_help_message".local())
    }

    @objc func simulateShotWithPen() {
        shootWithPen(true)
    }

    @objc func simulateShotWithNoPen() {
        shootWithPen(false)
    }

    func shootWithPen(_ pen: Bool) {
        guard let armor = armor, let ammo = ammo else { fatalError() }

        let damage = calculator.calculateDurabilityDamage(armor: armor, ammo: ammo, didPen: pen)
        durabilitySlider.value -= Float(damage)

        updateCalculator()
    }

    func showAmmoOptions() {
        if let options = ammoOptions {
            let selectAmmoVC = SortableTableViewController(selectionDelegate: self, config: AmmoSortConfig(options: options), currentSelection: ammo)
            let nc = BaseNavigationController(rootViewController: selectAmmoVC)
            present(nc, animated: true, completion: nil)
        } else {
            let hud = JGProgressHUD(style: .dark)
            hud.position = .center
            hud.show(in: self.scrollView)

            dbManager.getAllAmmo { allAmmo in
                hud.dismiss(animated: false)
                self.ammoOptions = allAmmo.compactMap { SimulationAmmo(json:$0.json) }
                self.showAmmoOptions()
            }
        }
    }

    func showArmorOptions() {
        if let options = armorOptions {
            let selectArmorVC = SortableTableViewController(selectionDelegate: self, config: ArmorSortConfig(options: options), currentSelection: armor)
            let nc = BaseNavigationController(rootViewController: selectArmorVC)
            present(nc, animated: true, completion: nil)
        } else {
            let hud = JGProgressHUD(style: .dark)
            hud.position = .center
            hud.show(in: self.scrollView)

            dbManager.getAllArmor { allArmor in
                hud.dismiss(animated: false)
                self.armorOptions = allArmor.compactMap { SimulationArmor(json:$0.json) }
                self.showArmorOptions()
            }
        }
    }

    @objc func updateCalculator() {
        selectionCollectionView.reloadData()

        if let armor = armor, let ammo = ammo {
            let durability = Int(durabilitySlider.value)
            armor.currentDurability = durability

            let midPoint: CGFloat = 50.0;
            let penChance: CGFloat = CGFloat(calculator.penetrationChance(armor: armor, ammo: ammo))
            let redAmount = penChance < midPoint ? 1.0 - (penChance / midPoint) : 0.0
            let greenAmount = penChance < midPoint ? 0.0 : ((penChance - midPoint) / midPoint)
            let blueAmount = 1.0 - (abs(midPoint - penChance) / midPoint)
            let resultColor = UIColor.init(red: CGFloat(redAmount), green: CGFloat(greenAmount), blue: CGFloat(blueAmount), alpha: 1.0)

            resultLabel.textColor = resultColor
            resultLabel.text = String(format: "%.1f", penChance) + "%"

            durabilityValueLabel.text = "\(Int(durabilitySlider.value)) / \(Int(durabilitySlider.maximumValue))"
            durabilitySlider.tintColor = resultColor

            penButton.enable(durability > 0)
            noPenButton.enable(durability > 0)
        } else {
            resultLabel.text = "-"
        }
    }
}

// MARK:- Sortable Selection Delegate
extension PenChanceCalcViewController: SortableItemSelectionDelegate {
    func itemSelected(_ selection: Sortable) {
        switch selection {
        case let selectedArmor as SimulationArmor: armor = selectedArmor
        case let selectedAmmo as SimulationAmmo: ammo = selectedAmmo
        default: fatalError()
        }

        if let _ = armor, let _ = ammo {
            penButton.enable(true)
            noPenButton.enable(true)
        }

        dismiss(animated: true, completion: nil)
    }

    func selectionCancelled() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK:- Collection View
extension PenChanceCalcViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: selectionCellId, for: indexPath) as! ItemPreviewCell
        cell.item = indexPath.item == 0 ? ammo : armor
        cell.thumbnailImageView.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        cell.placeholderText = indexPath.item == 0 ? Localized("select_ammo") : Localized("select_armor")
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            showAmmoOptions()
        } else {
            showArmorOptions()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { _ in
            self.selectionCollectionView.collectionViewLayout.invalidateLayout()
        }, completion:nil)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalWidth = collectionView.frame.width - 20.0
        let height = collectionView.frame.height * 0.9
        let width = totalWidth / 2.0
        return CGSize.init(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.init(top: 0, left: 10, bottom: 0, right: 10)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
